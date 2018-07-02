require "rails_helper"

describe Admin::Venues::Groups::SubscriptionsController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, :with_users, company: company }
  let!(:group) { create :group, venue: venue, owner: venue.users.first, priced_duration: :season }
  let!(:group_season) { create :group_season, group: group }

  before { sign_in_for_api_with admin }

  describe "#index" do
    subject { get :index, venue_id: venue.id, group_id: group.id }

    let!(:group_subscription1) { create :group_subscription, group_season: group_season }
    let!(:group_subscription2) { create :group_subscription, group_season: group_season }
    let!(:other_group) { create :group, venue: venue, priced_duration: :season }
    let!(:other_group_season) { create :group_season, group: other_group }
    let!(:other_group_subscription) { create :group_subscription, group_season: other_group_season }

    let(:subscription_ids) { json['subscriptions'].map { |x| x['id'] } }

    it 'returns group subscriptions JSON' do
      is_expected.to be_success
      expect(subscription_ids).to eq [group_subscription1.id, group_subscription2.id]
    end

    it 'returns correct data' do
      is_expected.to be_success
      subscription_data = json['subscriptions'].first

      expect(subscription_data.dig('user', 'id')).to eq group_subscription1.user_id
      expect(subscription_data).to include('group_id' => group_subscription1.group.id,
                                           'start_date' => group_subscription1.start_date.to_s,
                                           'end_date' => group_subscription1.end_date.to_s,
                                           'payable' => group_subscription1.payable?)
    end
  end

  describe "#destroy" do
    subject { delete :destroy, venue_id: venue.id, group_id: group.id, id: group_subscription.id }

    let!(:group_subscription) { create :group_subscription, group_season: group_season }

    it "cancels group subscription" do
      expect{ subject }.to change { group.subscriptions.active.count }.by(-1)
                       .and change { group.subscriptions.cancelled.count }.by(1)

      is_expected.to be_success
      expect(json).to eq [group_subscription.id]
    end
  end

  describe "#destroy_many" do
    subject { patch :destroy_many, venue_id: venue.id, group_id: group.id, **params }

    let!(:group_subscription1) { create :group_subscription, group_season: group_season }
    let!(:group_subscription2) { create :group_subscription, group_season: group_season }
    let!(:other_group_subscription) { create :group_subscription, group_season: group_season }

    let(:params) { { subscription_ids: [group_subscription1.id, group_subscription2.id] } }

    it "cancels group subscriptions" do
      expect{ subject }.to change { group.subscriptions.active.count }.by(-2)
                       .and change { group.subscriptions.cancelled.count }.by(2)

      is_expected.to be_success
      expect(json).to eq [group_subscription1.id, group_subscription2.id]
    end
  end

  describe "#mark_paid_many" do
    subject { patch :mark_paid_many, venue_id: venue.id, group_id: group.id, **params }

    let!(:group_subscription1) { create :group_subscription, group_season: group_season }
    let!(:group_subscription2) { create :group_subscription, group_season: group_season }
    let!(:other_group_subscription) { create :group_subscription, group_season: group_season }

    let(:params) { { subscription_ids: [group_subscription1.id, group_subscription2.id] } }

    it "marks group subscriptions as paid" do
      expect{ subject }.to change { group.subscriptions.invoiceable.count }.by(-2)

      is_expected.to be_success
      expect(json).to eq [group_subscription1.id, group_subscription2.id]
    end

    context 'with partial amount' do
      let(:params) do
        { subscription_ids: [group_subscription1.id, group_subscription2.id], amount: 3 }
      end

      it "partially pays subscriptions" do
        expect{ subject }.to do_not_change { group.subscriptions.invoiceable.count }
                         .and change { group_subscription1.reload.amount_paid }.to(3)
                         .and do_not_change { group_subscription1.reload.is_paid }

        is_expected.to be_success
        expect(json).to eq [group_subscription1.id, group_subscription2.id]
      end
    end
  end

  describe "#mark_unpaid_many" do
    subject { patch :mark_unpaid_many, venue_id: venue.id, group_id: group.id, **params }

    let!(:group_subscription1) { create :group_subscription, group_season: group_season, is_paid: true }
    let!(:group_subscription2) { create :group_subscription, group_season: group_season, is_paid: true }
    let!(:other_group_subscription) { create :group_subscription, group_season: group_season, is_paid: true }

    let(:params) { { subscription_ids: [group_subscription1.id, group_subscription2.id] } }

    it "marks group subscriptions as unpaid" do
      expect{ subject }.to change { group.subscriptions.invoiceable.count }.by(2)

      is_expected.to be_success
      expect(json).to eq [group_subscription1.id, group_subscription2.id]
    end
  end
end
