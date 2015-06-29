class BrokerAgencyProfile
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :organization

  MARKET_KINDS = %W[individual shop both]

  field :entity_kind, type: String
  field :market_kind, type: String
  field :corporate_npn, type: String
  field :primary_broker_role_id, type: BSON::ObjectId

  field :languages_spoken, type: String # TODO
  field :working_hours, type: Boolean
  field :accept_new_clients, type: Boolean

  field :aasm_state, type: String
  field :aasm_state_set_on, type: Date

  embeds_one  :inbox, as: :recipient, cascade_callbacks: true
  accepts_nested_attributes_for :inbox

  has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
  accepts_nested_attributes_for :broker_agency_contacts, reject_if: :all_blank, allow_destroy: true

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :home_page, :home_page=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  validates_presence_of :market_kind, :entity_kind, :primary_broker_role_id

  validates :corporate_npn, 
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },    
    uniqueness: true,
    allow_blank: true

  validates :market_kind,
    inclusion: { in: MARKET_KINDS, message: "%{value} is not a valid market kind" },
    allow_blank: false

  validates :entity_kind,
    inclusion: { in: Organization::ENTITY_KINDS[0..3], message: "%{value} is not a valid business entity kind" },
    allow_blank: false

  after_initialize :build_nested_models

  # has_many employers
  def employer_clients
    return unless (MARKET_KINDS - ["individual"]).include?(market_kind)
    return @employer_clients if defined? @employer_clients
    @employer_clients = EmployerProfile.find_by_broker_agency_profile(self)
  end

  # TODO: has_many families
  def family_clients
    return unless (MARKET_KINDS - ["shop"]).include?(market_kind)
    return @family_clients if defined? @family_clients
    @family_clients = Family.find_by_broker_agency_profile(self.id)
  end

  # has_one primary_broker_role
  def primary_broker_role=(new_primary_broker_role = nil)
    if new_primary_broker_role.present?
      raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker_role.is_a? BrokerRole
      self.primary_broker_role_id = new_primary_broker_role._id
    else
      unset(new_primary_broker_role)
    end
    @primary_broker_role = new_primary_broker_role
  end

  def primary_broker_role
    return @primary_broker_role if defined? @primary_broker_role
    @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
  end

  # has_many active broker_roles
  def active_broker_roles
    # return @active_broker_roles if defined? @active_broker_roles
    @active_broker_roles = BrokerRole.find_active_by_broker_agency_profile(self)
  end

  # has_many candidate_broker_roles
  def candidate_broker_roles
    # return @candidate_broker_roles if defined? @candidate_broker_roles
    @candidate_broker_roles = BrokerRole.find_candidates_by_broker_agency_profile(self)
  end

  # has_many inactive_broker_roles
  def inactive_broker_roles
    # return @inactive_broker_roles if defined? @inactive_broker_roles
    @inactive_broker_roles = BrokerRole.find_inactive_by_broker_agency_profile(self)
  end

  # alias for broker_roles
  def writing_agents
    active_broker_roles
  end

  # alias for broker_roles - deprecate
  def brokers
    active_broker_roles
  end

  def legal_name
    organization.legal_name
  end

  def market_kind=(new_market_kind)
    write_attribute(:market_kind, new_market_kind.to_s.downcase)
  end

  def is_active?
    self.is_approved?
  end

  ## Class methods
  class << self
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.broker_agency_profile }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      list_embedded Organization.exists(broker_agency_profile: true).order_by([:legal_name]).to_a
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      organizations = Organization.where("broker_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
      organizations.size > 0 ? organizations.first.broker_agency_profile : nil
    end

  end


  aasm do #no_direct_assignment: true do
    state :is_applicant, initial: true
    state :is_approved
    state :is_rejected
    state :is_suspended
    state :is_closed

    event :approve do
      transitions from: [:is_applicant, :is_suspended], to: :is_approved
    end

    event :reject do
      transitions from: :is_applicant, to: :is_rejected
    end

    event :suspend do
      transitions from: [:is_applicant, :is_approved], to: :is_suspended
    end

    event :close do
      transitions from: [:is_approved, :is_suspended], to: :is_closed
    end
  end

private

  def build_nested_models
    build_inbox if inbox.nil?
  end
end
