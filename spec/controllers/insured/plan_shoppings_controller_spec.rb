require 'rails_helper'

RSpec.describe Insured::PlanShoppingsController, :type => :controller do
  let(:plan) { double }
  let(:hbx_enrollment) { double }
  let(:benefit_group) {double}
  let(:reference_plan) {double}
  let(:usermailer) {double}
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }

  context "POST checkout" do
    before do
      allow(Plan).to receive(:find).with("plan_id").and_return(plan)
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:plan=).with(plan).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(:reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:select_coverage!).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(UserMailer).to receive(:plan_shopping_completed).and_return(usermailer)
      allow(usermailer).to receive(:deliver_now).and_return(true)
    end

    it "returns http success" do
      sign_in
      post :checkout, id: "hbx_id", plan_id: "plan_id"
      expect(response).to have_http_status(:redirect)
    end
  end

  context "GET receipt" do

    let(:person) { double("Person") }
    let(:user) { double("User") }
    let(:enrollment) { double("HbxEnrollment") }
    let(:plan) { double("Plan") }
    let(:benefit_group) { double("BenefitGroup") }
    let(:reference_plan) { double("Plan") }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).with("id").and_return(enrollment)
      allow(enrollment).to receive(:plan).and_return(plan)
      allow(enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
    end

    it "returns http success" do
      sign_in(user)
      get :receipt, id: "id"
      expect(response).to have_http_status(:success)
    end
  end

  context "POST thankyou" do

    let(:person) { double("Person") }
    let(:user) { double("User") }
    let(:enrollment) { double("HbxEnrollment") }
    let(:plan) { double("Plan") }
    let(:benefit_group) { double("BenefitGroup") }
    let(:reference_plan) { double("Plan") }
    let(:family) { double("Family") }
    let(:plan_year) { double("PlanYear") }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).with("id").and_return(enrollment)
      allow(Plan).to receive(:find).with("plan_id").and_return(plan)
      allow(enrollment).to receive(:plan).and_return(plan)
      allow(enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:is_eligible_to_enroll?).and_return(true)
      allow(benefit_group).to receive(:plan_year).and_return(plan_year)
      allow(plan_year).to receive(:is_eligible_to_enroll?).and_return(true)
    end

    it "returns http success" do
      sign_in(user)
      post :thankyou, id: "id", plan_id: "plan_id"
      expect(response).to have_http_status(:success)
    end
  end


  context "POST terminate" do
    before do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:terminate_coverage!).and_return(true)
      sign_in
    end

    it "returns http success" do
      post :terminate, id: "hbx_id"
      expect(response).to be_redirect
    end

    it "goes back" do
      request.env["HTTP_REFERER"] = terminate_insured_plan_shopping_url(1)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(false)
      post :terminate, id: "hbx_id"
      expect(response).to redirect_to(:back)
    end
  end

  context "POST waive" do
    before :each do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:shopping?).and_return(true)
      sign_in user
    end

    it "should get success flash message" do
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(hbx_enrollment).to receive(:waive_coverage).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("waiver").and_return(true)
      post :waive, id: "hbx_id", waiver_reason: "waiver"
      expect(flash[:notice]).to eq "Waive Successful"
      expect(response).to be_redirect
    end

    it "should get failure flash message" do
      allow(hbx_enrollment).to receive(:valid?).and_return(false)
      post :waive, id: "hbx_id", waiver_reason: "waiver"
      expect(flash[:alert]).to eq "Waive Failure"
      expect(response).to be_redirect
    end
  end
end
