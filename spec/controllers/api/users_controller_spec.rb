require "rails_helper"

describe API::UsersController, type: :controller do
  let(:unconfirmed_user) { create :user, :unconfirmed_with_password }
  let(:confirmed_user) { create :user }
  let(:empty_password_user) { create :user, :unconfirmed }
  let(:valid_params) { attributes_for(:user) }

  describe "Email Check" do
    before { user = User.create(email: 'email@check.com', first_name: 'Test', last_name: 'Test') }
    context "with valid email" do
      it "will find user and return 200" do
        get :email_check, { email: 'email@check.com' }
        response_body = JSON.parse(response.body.to_s)
        expect(response.status).to eql 200
        expect(response_body['message']).to eql I18n.t('api.users.email_check.success')
      end
    end

    context "with invalid email" do
        it "will return 422 and an error message" do
          get :email_check, { email: 'email@google' }
          response_body = JSON.parse(response.body.to_s)
          expect(response.status).to eql 422
          expect(response_body['message']).to eql I18n.t('api.users.email_check.error')
        end
    end

    context "with no email param" do
        it "will return 422 and message that email is missing" do
          get :email_check
          response_body = JSON.parse(response.body.to_s)
          expect(response.status).to eql 422
          expect(response_body['message']).to eql I18n.t('api.users.email_check.email_required')
        end
    end
  end

  describe "POST create" do
    subject { post :create, user: params }
    let(:params) { attributes_for(:user) }

    context "with valid params" do
      let(:created_user) { User.last }
      it "creates user and returns as JSON" do
        expect(AuthToken).to receive(:encode).with(a_hash_including('email' => params[:email])).and_return('abc123')
        expect { subject }.to change(User, :count).by(1)
        expect(created_user.email).to eq params[:email]
        expect(response.body).to eq({ auth_token: 'abc123' }.to_json)
        is_expected.to be_success
      end

      it "encodes clock format" do
        expect(AuthToken).to receive(:encode).with(a_hash_including('clock_type' => "24h")).and_return('abc123')
        expect { subject }.to change(User, :count).by(1)
      end

      context 'with country set' do
        let(:params) { attributes_for(:user).merge(default_country_id: 2) }
        it 'saves user preferred country' do
          expect(AuthToken).to receive(:encode).with(a_hash_including('country_code' => 'US')).and_return('abc123')
          expect { subject }.to change(User, :count).by(1)
          expect(created_user.default_country_id).to eq 2
        end
      end
    end

    context "with invalid params" do
      let(:params) { attributes_for(:user).tap { |x| x.delete(:email) } }

      it "does not create a user" do
        expect { subject }.not_to change(User, :count)
        is_expected.to be_unprocessable
      end
    end

    context 'with already existed email' do
      it 'returns JSON with errors' do
        post :create, { user: { email: unconfirmed_user.email } }
        response_body = JSON.parse(response.body)

        expect(response.status).to eql 422
        expect(response_body['error']).to eql('already_exists')
      end
    end

    context 'with unconfirmed user' do
      it 'returns JSON with errors' do
        post :create, { user: { email: empty_password_user.email } }
        response_body = JSON.parse(response.body)

        expect(response.status).to eql 422
        expect(response_body['error']).to eql('unconfirmed_account')
      end
    end
  end

  describe 'POST confirmation email' do
    context 'with missing email parameter' do
      it 'does not send account confirmation instructions' do
        post :confirm_account_email
        response_body = JSON.parse(response.body.to_s)

        expect(response.status).to eql 422
        expect(response_body['message']).to eql I18n.t('api.users.confirm_account.email_required')
      end
    end

    context 'with correct email parameter' do
      it 'send confirmation instructions to the email' do
        post :confirm_account_email, { user: { email: 'test4@test.com' } }.to_json
        response_body = JSON.parse(response.body.to_s)

        expect(response.status).to eql 200
        expect(response_body['message']).to eql I18n.t('api.users.confirm_account.success')
      end
    end
  end

  describe 'PATCH update' do
    subject { patch :update, { id: user_id_param, user: params } }
    let(:params) { { first_name: 'FirstName' } }
    let(:user_id_param) { 1 }
    let(:response_body) { JSON.parse(response.body.to_s) }
    let(:errors) { response_body['errors'] }

    context 'with unauthorized user' do
      it 'renders errors' do
        is_expected.to be_unauthorized
        expect(errors).to eq [I18n.t('api.authentication.unauthorized')]
      end
    end

    context 'when trying to update wrong user' do
      let!(:current_user) { create :user }
      let!(:wrong_user) { create :user }
      let(:user_id_param) { wrong_user.id }
      before { sign_in_for_api_with(current_user) }

      it 'does not update user' do
        # This one is tricky: we are trying to update a user A when logged in
        # as user B. Now this thing updates our own user (regardless of user id passed in)
        # That's bearable and we don't really care, we just need to make sure that
        # we don't update the other user (so that it is not a security breach)
        expect { subject }.not_to change { wrong_user.reload.attributes }
        expect(subject.status).not_to eq 500
      end
    end

    context 'with valid user' do
      let!(:current_user) { create :user }
      before { sign_in_for_api_with(current_user) }
      it 'updates the user' do
        expect { subject }.to change { current_user.reload.first_name }.to(params[:first_name])
        is_expected.to be_success
        expect(response_body['message']).to eql I18n.t('api.users.profile_updated')
      end

      context 'with wrong params' do
        let(:params) { { first_name: '' } }
        it 'does not update the user and renders error' do
          expect { subject }.not_to change { current_user.reload.attributes }
          is_expected.to be_unprocessable
        end
      end

      context 'when updating the password' do
        let(:params) do
          { current_password: current_password,
            password: new_password,
            password_confirmation: new_password }
        end

        context 'with incorrect current_password' do
          let(:current_password) { 'just_random_string' }
          let(:new_password) { 'p' * 8 }
          let(:i18n_path) { 'activerecord.errors.models.user.attributes.current_password.invalid' }
          let(:error_message) { "Current password #{I18n.t(i18n_path)}" }

          it 'does not update the user password' do
            expect { subject }.not_to change { current_user.reload.attributes }
            is_expected.to be_unprocessable
            expect(response_body['message']).to eq [error_message]
          end
        end

        context 'with incorrect new password' do
          let(:new_password) { '123' }
          let(:current_password) { current_user.password }
          let(:i18n_path) { 'activerecord.errors.models.user.attributes.password.too_short' }
          let(:error_message) { "Password #{I18n.t(i18n_path)}" }

          it 'does not update the user password' do
            expect { subject }.not_to change { current_user.reload.attributes }
            is_expected.to be_unprocessable
            expect(response_body['message']).to eq [error_message]
          end
        end

        context 'with correct password and current_password' do
          let(:new_password) { 'legit-password123' }
          let(:current_password) { current_user.password }
          let(:success_message) { I18n.t('api.users.password_updated') }
          it 'does not update the user password' do
            expect { subject }.to change { current_user.reload.encrypted_password }
            is_expected.to be_success
            expect(response_body['message']).to eq success_message
          end
        end
      end
    end
  end

  describe 'POST change_location' do
    let(:params) { { user_id: confirmed_user.id,
                     location: { latitude: 1000.0,
                                 longitude: 2340.0,
                                 current_city: 'Cairo'} } }
    subject { post :change_location, params}

    before do
      sign_in_for_api_with(confirmed_user)
    end

    it 'is successful' do
      expect(subject.status).to eq(200)
    end

    it 'changes user location' do
      expect { subject }.to change { User.last.latitude }.from(nil).to(1000.0)
                         .and change { User.last.longitude }.from(nil).to(2340.0)
                         .and change { User.last.current_city }.from(nil).to('Cairo')
    end
  end

  describe "DELETE destroy" do
    subject { delete :destroy, { id: user_id_param } }
    let(:user_id_param) { 1 }
    let(:response_body) { JSON.parse(response.body.to_s) }
    let(:errors) { response_body['errors'] }

    context 'with unauthorized user' do
      it 'renders errors' do
        is_expected.to be_unauthorized
        expect(errors).to eq [I18n.t('api.authentication.unauthorized')]
      end
    end

    context 'when trying to delete wrong user' do
      let!(:current_user) { create :user }
      let!(:wrong_user) { create :user }
      let(:user_id_param) { wrong_user.id }
      before { sign_in_for_api_with(current_user) }

      it 'should delete current user' do
        expect { subject }.to change(User, :count).by(-1)
        expect { wrong_user.reload }.not_to raise_error
        expect { current_user.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(subject.status).not_to eq 500
      end
    end

    context 'with valid user' do
      let!(:current_user) { create :user }
      before { sign_in_for_api_with(current_user) }

      context 'with due payment' do
        let!(:reservation) { create :reservation, user: current_user, payment_type: :semi_paid }
        it 'does not delete the user' do
          expect { subject }.not_to change(User, :count)
          expect { current_user.reload }.not_to raise_error
          expect(subject.status).to eq 422
          expect(response_body['message']).to eql I18n.t('api.users.errors.due_payment_delete')
        end
      end

      context 'with no due payment' do
        it 'deletes the user' do
          expect { subject }.to change(User, :count).by(-1)
          expect { current_user.reload }.to raise_error ActiveRecord::RecordNotFound
          is_expected.to be_success
          expect(response_body['message']).to eql I18n.t('api.users.user_deleted')
        end

        context 'with devices and favourite venues' do
          let!(:device) { create :device, user: current_user }
          let!(:favorite_venue) { create :favourite_venue, user: current_user }
          it 'deletes the user' do
            expect { subject }.to change(User, :count).by(-1)
            is_expected.to be_success
          end
        end
      end
    end
  end

  describe "GET game_passes" do
    render_views
    subject { get :game_passes, {user_id: user_id_param, format: :json} }
    let(:user_id_param) { 99 }
    let(:response_body) { JSON.parse(response.body) }
    let(:errors) { response_body['errors'] }

    context 'with unauthorized user' do
      it 'renders errors' do
        is_expected.to be_unauthorized
        expect(errors).to eq [I18n.t('api.authentication.unauthorized')]
      end
    end

    context "with authorized user" do
      let!(:current_user) { create :user }
      let(:user_id_param) { current_user.id }
      let!(:user_game_passes) { create_list(:game_pass, 3, user: current_user) }
      let!(:other_game_pass) { create(:game_pass) }
      before { sign_in_for_api_with(current_user) }

      it "should return game passes list for the user in the venue" do
        expect(subject).to be_success
        expect(response_body['game_passes'].count).to eq user_game_passes.count
      end
    end
  end

  describe 'POST #upload_photo' do
    subject { post :upload_photo, photo: fixture_file_upload('test_image.png', 'image/png') }
    let(:current_user) { create :user }
    before { sign_in_for_api_with(current_user) }

    it 'is successful' do
      expect(subject.status).to eq(200)
    end

    it 'uploads image' do
      expect { subject }.to change { current_user.reload.photo.file? }.from(false).to(true)
    end
  end
end
