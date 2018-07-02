require 'rails_helper'

describe Admin::Venues::Emails::CustomEmailsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }
  let!(:venue) { create :venue, :with_users, user_count: 2, company: company }
  let!(:user) { venue.users.first }
  let!(:other_user) { venue.users.second }
  let!(:email_list) { create :email_list, venue: venue, users: [user, other_user] }
  let!(:custom_mail) { create :custom_mail, venue: venue,
                                            email_lists: [email_list],
                                            recipient_users: 'rec1@m.test,rec2@m.test' }

  describe '#index' do
    subject { get :index, format: :json, venue_id: venue.id }

    let!(:other_venue_user) { create :user }

    let(:body) { JSON.parse response.body }

    it 'returns custom emails JSON' do
      is_expected.to be_success
      expect(body['custom_emails'].map { |x| x['id'] } ).to eq [custom_mail.id]
    end

    it 'returns custom email recipient emails' do
      is_expected.to be_success
      recipient_emails = body['custom_emails'].first['recipient_emails']
      expect(recipient_emails).to match_array [user.email, other_user.email, 'rec1@m.test', 'rec2@m.test']
    end
  end

  describe '#create' do
    subject { post :create, format: :json, venue_id: venue.id, custom_email: params }

    context 'with valid params' do
      let(:params) { {
        from: 'admin@mail.test',
        body: 'body sample',
        subject: 'test sample',
        to_users: 'rec1@m.test,rec2@m.test',
        to_groups: [email_list.id]
      } }

      it 'creates a custom email' do
        expect { subject }.to change { venue.custom_mails.count }.by(1)
        is_expected.to be_created
      end

      it 'adds list to custom email' do
        is_expected.to be_created
        expect(venue.custom_mails.last.email_lists).to include email_list
      end

      it 'adds recipient_users to custom email' do
        is_expected.to be_created
        expect(venue.custom_mails.last.recipient_users).to eq 'rec1@m.test,rec2@m.test'
      end
    end

    context 'with invalid params' do
      let(:params) { { from: '' } }

      it 'does not work' do
        expect { subject }.not_to change { venue.custom_mails.count }
        is_expected.to be_unprocessable
      end
    end

  end
end
