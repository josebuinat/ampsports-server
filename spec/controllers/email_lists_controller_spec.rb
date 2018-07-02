require 'rails_helper'

describe EmailListsController do
  let!(:venue) { create(:venue) }
  let!(:email_lists) { create_list(:email_list, 5, :with_users, venue: venue) }

  describe "GET index" do
    context "without admin login" do
      it "should redirect to admin sign in page" do
        get :index, {venue_id: venue.id}

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}

      before do
        sign_in admin
      end

      context "html request" do
        before do
          get :index, { venue_id: venue.id, format: 'html'}
        end

        it "should respond with success 200" do
          expect(response).to be_success
        end

        it "should render email_list/_index template" do
          expect(response).to render_template(partial: 'email_lists/_index')
        end
      end

      context "json request" do
        before do
          get :index, { venue_id: venue.id, format: 'json'}
        end

        it "should respond with success 200" do
          expect(response).to be_success
        end

        it "should return email lists as json" do
          expect(response.body).to eq(email_lists.to_json)
        end
      end
    end
  end

  describe "GET show" do
    let!(:email_list) { venue.email_lists.first }

    context "without admin login" do
      it "should redirect to admin sign in page" do
        get :show, {venue_id: venue.id, id: email_list.id}

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}

      before do
        sign_in admin
        get :show, {venue_id: venue.id, id: email_list.id}
      end

      it "should response with success 200" do
        expect(response).to be_success
      end

      it "should render email_lists/_email_list template" do
        expect(response).to render_template('email_lists/_email_list')
      end
    end
  end

  describe "POST create" do
    let!(:email_list_params) { attributes_for(:email_list) }

    context "without admin login" do
      it "should redirect to admin sign in page" do
        post :create, {venue_id: venue.id, email_list: email_list_params}

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}
      before do
        sign_in admin
        post :create, {venue_id: venue.id, email_list: email_list_params}
      end

      it "should response with success 200" do
        expect(response).to be_success
      end

      it "should respond with json" do
        expect(response.body).to include(EmailList.find_by_name(email_list_params[:name]).to_json)
      end
    end
  end

  describe "POST update" do
    let!(:email_list) { venue.email_lists.first }
    let!(:updated_params) {
      email_list.name += " updated"
      email_list.attributes
    }

    context "without admin login" do
      it "should redirect to admin sign in page" do
        post :update, {venue_id: venue.id, id: email_list.id, email_list: updated_params}

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}
      before do
        sign_in admin
        post :update, {venue_id: venue.id, id: email_list.id, email_list: updated_params}
      end

      it "should response with success 200" do
        expect(response).to be_success
      end

      it "should respond with json" do
        expect(response.body).to include(EmailList.find(email_list.id).to_json)
      end
    end
  end

  describe "POST remove_users" do
    let!(:email_list) {
      create(:email_list,
        :with_users, user_count: 5, venue: venue
      )
    }
    let!(:users_to_del) { email_list.users[1..2].map(&:id) }

    context "without admin login" do
      it "should redirect to admin sign in page" do
        post :remove_users, {venue_id: venue.id, email_list_id: email_list.id, users: users_to_del}

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}
      before do
        sign_in admin
        post :remove_users, {venue_id: venue.id, email_list_id: email_list.id, users: users_to_del}
      end

      it "should response with success 200" do
        expect(response).to be_success
      end

      it "should respond with json" do
        expect(response.body).to include(I18n.t('email_lists.remove_users.success'))
      end
    end
  end

  describe "GET off_list_users" do
    let!(:email_list) {
      create(:email_list,
        :with_users, user_count: 5, venue: venue
      )
    }

    let!(:other_users) {
      users = create_list(:user, 10, venues: [venue])
      venue.reload
      users
    }

    context "without admin login" do
      it "should redirect to admin sign in page" do
        get :off_list_users, { venue_id: venue.id, email_list_id: email_list.id, per_page: 100 }

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}
      before do
        sign_in admin
        get :off_list_users, { venue_id: venue.id, email_list_id: email_list.id, per_page: 100 }
      end

      it "should response with success 200" do
        expect(response).to be_success
      end

      it "should respond with json" do
        expect(JSON.parse(response.body)['users'].count).to eq(venue.users.count - email_list.users.count)
      end
    end
  end

  describe "GET listed_users" do
    let!(:email_list) {
      create(:email_list,
        :with_users, user_count: 5, venue: venue
      )
    }

    let!(:other_users) {
      users = create_list(:user, 10, venues: [venue])
      venue.reload
      users
    }

    context "without admin login" do
      it "should redirect to admin sign in page" do
        get :listed_users, { venue_id: venue.id, email_list_id: email_list.id, per_page: 100 }

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}
      before do
        sign_in admin
        get :listed_users, { venue_id: venue.id, email_list_id: email_list.id, per_page: 100 }
      end

      it "should response with success 200" do
        expect(response).to be_success
      end

      it "should respond with users json" do
        expect(JSON.parse(response.body)['users'].count).to eq(email_list.users.count)
      end
    end
  end

  describe "POST add_users" do
    let(:email_list) { venue.email_lists.first }
    let!(:prev_users_count) { email_list.users.count }
    let!(:all_users) {
      users = create_list(:user, 10, venues: [venue])
      venue.reload
      users
    }
    let!(:users_to_add) { all_users[1..5].map(&:id)}

    context "without admin login" do
      it "should redirect to admin sign in page" do
        post :add_users, { venue_id: venue.id, email_list_id: email_list.id, users: users_to_add }

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}

      before do
        sign_in admin
        post :add_users, params
      end

      context "add selected users" do
        let(:params) { {venue_id: venue.id, email_list_id: email_list.id, users: users_to_add} }

        it "should response with success 200" do
          expect(response).to be_success
        end

        it "should respond with json" do
          expect(response.body).to include(I18n.t('.email_lists.add_users.success'))
        end

        it "should add users to email_list" do
          expect(email_list.users.count).to eq(users_to_add.count + prev_users_count)
        end
      end

      context "add all venue users" do
        let(:params) { {venue_id: venue.id, email_list_id: email_list.id, add_all: true} }

        it "should response with success 200" do
          expect(response).to be_success
        end

        it "should add all venue users to email_list" do
          expect(email_list.users.count).to eq(venue.users.count)
        end
      end
    end
  end

  describe "POST destroy" do
    let(:email_list) { venue.email_lists.first }

    context "without admin login" do
      it "should redirect to admin sign in page" do
        post :destroy, { venue_id: venue.id, id: email_list.id }

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}
      before do
        sign_in admin
        post :destroy, { venue_id: venue.id, id: email_list.id }
      end

      it "should response with success 200" do
        expect(response).to be_success
      end

      it "should respond with json" do
        expect{email_list.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect(response.body).to include(I18n.t('.email_lists.destroy.success'))
      end
    end
  end

  describe "POST custom_mail" do
    let(:other_users) { create_list(:user, 2) }
    let!(:mail_params) {
      { to_groups: venue.email_lists[1..2].map(&:id),
        to_users: other_users.map(&:email).join(','),
        from: "test-no-reply@test.test",
        subject: "test subject",
        body: "Hi\n\n This is test email. \n\nBr,\n Playven",
        send_copy: true
      }
    }
    let!(:image) { mock_file_upload('rails.png', 'image/png') }

    context "without admin login" do
      it "should redirect to admin sign in page" do
        post :custom_mail, { venue_id: venue.id, custom_mail: mail_params.to_json, image: image}

        expect(response).to redirect_to(new_admin_session_url)
      end
    end

    context "with admin login" do
      let!(:admin) {create(:admin)}
      before do
        ActionMailer::Base.deliveries.clear
        CustomMailWorker.clear
        sign_in admin
        post :custom_mail, { venue_id: venue.id, custom_mail: mail_params.to_json, image: image, format: 'js' }
      end

      it "should response with success 200" do
        expect(response).to be_success
      end

      it "should respond with json" do
        expect(response.body).to include(I18n.t('.email_lists.custom_mail.success'))
      end

      it "should send copy email" do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it "should add mailer job queue" do
        expect(CustomMailWorker.jobs.size).to eq(1)
      end

      it "should send custom mails" do
        ActionMailer::Base.deliveries.clear
        CustomMailWorker.drain
        expect(ActionMailer::Base.deliveries.count).to be > 0
      end
    end
  end

  after(:all) do
    ActionMailer::Base.deliveries.clear
    Sidekiq::Queues.clear_all
  end
end
