require 'rails_helper'

describe ActivityLog do
  let(:venue) { create(:venue, :with_courts) }
  let(:company) { venue.company }

  describe "attributes" do
    subject { build(:reservation_activity_log, :with_user, company: company) }

    it "should have attributes" do
      attrs = {
        activity_type: 'reservation_created',
        actor_type: 'User',
        payload_type: 'Reservation'
      }
      is_expected.to have_attributes(attrs)
    end
  end

  describe "record_log" do
    let(:admin) { create(:admin, company: company) }
    let(:membership) { create :membership, venue: venue }
    subject { ActivityLog.record_log(:membership_created, company.id, admin, membership) }

    it "should create an activity_log" do
      expect { subject }.to change(ActivityLog, :count).by(1)
      expect(subject).to be_truthy
      expect(ActivityLog.first.payload_details).not_to be_empty
    end
  end

  describe "description" do
    let(:activity_log) { create(:invoice_activity_log, :with_admin, company: company) }
    subject { activity_log.description }

    it { is_expected.not_to be_empty }
  end

  describe "search" do
    let!(:reservation_activity_log) { create(:reservation_activity_log, :with_user, company: company) }
    let!(:membership_activity_log) { create(:membership_activity_log, :with_admin, company: company) }
    let!(:invoice_activity_log) { create(:invoice_activity_log, :with_admin, company: company) }

    before { ActivityLog.all.each { |log| build_details_and_save(log) } }
    subject { ActivityLog.search(search_params) }

    context "search_term" do
      context "positive" do
        let(:search_params) {{ search_term: 'test' }}
        it { is_expected.not_to be_empty }
      end

      context "negative" do
        let(:search_params) {{ search_term: 'random-term-not-present' }}
        it { is_expected.to be_empty }
      end
    end

    context "filter_start_date" do
      context "positive" do
        let(:search_params) {{ filter_start_date: Date.current.to_s }}
        it { is_expected.not_to be_empty }
      end

      context "negative" do
        let(:search_params) {{ filter_start_date: Date.tomorrow.to_s }}
        it { is_expected.to be_empty }
      end
    end

    context "filter_end_date" do
      context "positive" do
        let(:search_params) {{ filter_end_date: Date.current.to_s }}
        it { is_expected.not_to be_empty }
      end

      context "negative" do
        let(:search_params) {{ filter_end_date: Date.yesterday.to_s }}
        it { is_expected.to be_empty }
      end
    end

    context "filter_payload_types" do
      context "positive" do
        let(:search_params) {{ filter_payload_types: 'reservation' }}
        it "should have correct payload types" do
          expect(subject.first.payload_type).to eq("Reservation")
          expect(subject.count).to eq(1)
        end
      end
    end

    context "filter_action_types" do
      context "positive" do
        let(:search_params) {{ filter_action_types: 'created' }}
        it "should have correct action types" do
          expect(subject.count).to eq(2)
        end
      end
    end
  end
end
