require "rails_helper"

RSpec.describe "employers/census_employees/_details.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:benefit_group_assignment) { double(benefit_group: benefit_group) }
  let(:benefit_group) {double(title: "plan name")}
  let(:hbx_enrollment) {double(waiver_reason: "this is reason", plan: double(name: "hbx enrollment plan name"), hbx_enrollment_members: [])}
  let(:plan) {double(total_premium: 10, total_employer_contribution: 20, total_employee_cost:30)}

  before(:each) do
    assign(:census_employee, census_employee)
    assign(:benefit_group_assignment, benefit_group_assignment)
    assign(:hbx_enrollment, hbx_enrollment)
    assign(:benefit_group, benefit_group)
    allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
  end

  it "should show the plan" do
    allow(benefit_group_assignment).to receive(:coverage_waived?).and_return(true)
    allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(hbx_enrollment)

    render template: "employers/census_employees/_details.html.erb"
    expect(rendered).to match /Plan/
    expect(rendered).to have_selector('p', text: 'Benefit Group: plan name')
  end

  it "should show waiver" do
    allow(benefit_group_assignment).to receive(:coverage_waived?).and_return(true)
    allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(hbx_enrollment)

    render template: "employers/census_employees/_details.html.erb"
    expect(rendered).to match /Coverage Waived/
  end

  it "should show waiver reason" do
    allow(benefit_group_assignment).to receive(:coverage_waived?).and_return(true)
    allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(hbx_enrollment)

    render template: "employers/census_employees/_details.html.erb"
    expect(rendered).to match /Waiver Reason: this is reason/
  end

  it "should show plan name" do
    allow(benefit_group_assignment).to receive(:coverage_waived?).and_return(false)
    allow(benefit_group_assignment).to receive(:coverage_selected?).and_return(true)
    allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(hbx_enrollment)

    render template: "employers/census_employees/_details.html.erb"
    expect(rendered).to match /Plan Name: hbx enrollment plan name/
  end

  it "should show plan cost" do
    allow(benefit_group_assignment).to receive(:coverage_waived?).and_return(false)
    allow(benefit_group_assignment).to receive(:coverage_selected?).and_return(true)
    assign(:plan, plan)

    render template: "employers/census_employees/_details.html.erb"
    expect(rendered).to match /Employer Contribution/
    expect(rendered).to match /You Pay/
  end

  it "should show the info of employee role" do
    allow(benefit_group_assignment).to receive(:coverage_waived?).and_return(false)
    allow(benefit_group_assignment).to receive(:coverage_selected?).and_return(true)
    allow(census_employee).to receive(:employee_role).and_return(double(hired_on: Date.new, effective_on: Date.new))

    render template: "employers/census_employees/_details.html.erb"
    expect(rendered).to match /ELIGIBLE FOR COVERAGE/
  end
end
