require "rails_helper"

describe API::Users::SubscriptionsController, type: :controller do
  let(:current_user) { create :user, :with_venues, venue_count: 2 }
  let(:venue) { current_user.venues.first }
  let(:venue2) { current_user.venues.second }

  describe 'PATCH #toggle_email_subscription' do
    render_views
    subject { patch :toggle_email_subscription, { user_id: current_user.id, venue_id: venue_param } }
    let(:response_body) { JSON.parse(response.body) }
    let(:errors) { response_body['errors'] }
    let(:venue_param) { nil }

    context 'with unauthorized user' do
      it 'renders errors' do
        is_expected.to be_unauthorized
        expect(errors).to eq [I18n.t('api.authentication.unauthorized')]
      end
    end

    context "with authorized user" do
      let!(:email_list1) { create :email_list, venue: venue, users: [current_user] }
      let!(:email_list2) { create :email_list, venue: venue2, users: [current_user] }
      let(:venue_param) { venue.id }

      before { sign_in_for_api_with(current_user) }

      context "with enabled subscription" do
        before { subject }

        it "unsubscribes user from that venue emails" do
          is_expected.to be_success
          expect(current_user.reload.subscription_enabled?(venue)).to be_falsey
        end

        it "removes user from email lists of the venue" do
          expect(email_list1.reload.user_ids).not_to include(current_user.id)
          expect(email_list2.reload.user_ids).to include(current_user.id)
        end
      end

      context "with disabled subscripiton" do
        before do
          connector = current_user.venue_user_connectors.find_by(venue: venue)
          connector.update(email_subscription: false)
          subject
        end

        it "subscribes user to that venue emails" do
          is_expected.to be_success
          expect(current_user.reload.subscription_enabled?(venue)).to be_truthy
        end
      end
    end
  end


  describe "GET venues" do
    render_views
    subject { get :venues, user_id: current_user.id, format: :json }

    let(:response_body) { JSON.parse(response.body) }
    let(:errors) { response_body['errors'] }

    context 'with unauthorized user' do
      it 'renders errors' do
        is_expected.to be_unauthorized
        expect(errors).to eq [I18n.t('api.authentication.unauthorized')]
      end
    end

    context "with authorized user" do
      before do
        sign_in_for_api_with(current_user)
        subject
      end

      it "returns venues list for the user" do
        is_expected.to be_success
        expect(response_body['venues'].count).to eq 2
      end
    end
  end
end
