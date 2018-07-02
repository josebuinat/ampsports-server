require 'rails_helper'

describe SocialLoginService do
  describe '#from_omniauth' do
    subject { described_class.from_omniauth(auth_object) }
    # auth object should support dot notation
    let(:auth_object) { OpenStruct.new(info: OpenStruct.new(info), uid: uid, provider: provider) }
    let(:provider) { 'facebook' }
    let(:uid) { '12345678' }

    # response is a tuple
    let(:error) { subject[0] }
    let(:returned_user) { subject[1] }
    let(:social_account) { returned_user.social_accounts.find_by(provider: provider) }

    context 'when it is a totally new user' do

      context 'with correct info object' do
        let(:attributes) { returned_user.attributes }
        let(:info) { {first_name: 'John', last_name: 'Dorian', email: 'john@dorian.com'} }

        it 'creates new user and assigns correct attributes' do
          expect { subject }.to change(User, :count).by(1)
          expect(attributes.slice('first_name', 'last_name', 'email')).to eq info.with_indifferent_access
          expect(error).to be_nil
        end

        it 'creates new associated social account with correct attributes' do
          expect { subject }.to change(User::SocialAccount, :count).by(1)
          expect(social_account.uid).to eq uid
        end

        it 'is created as confirmed' do
          expect(returned_user).to be_confirmed
        end
      end

      context 'with incorrect info object' do
        # no email / last_name
        let(:info) { { first_name: 'John' } }

        it 'does not create a new user' do
          expect { subject }.to do_not_change(User, :count).
            and do_not_change(User::SocialAccount, :count)
          expect(error).to eq 'social_network_error'
        end
      end
    end

    context 'when trying to log in' do
      let!(:user) { create :user, provider: 'facebook', uid: uid }
      let(:info) { user.attributes.slice('email', 'first_name', 'last_name') }

      it 'just logs in' do
        expect { subject }.to do_not_change(User, :count).
          and do_not_change(User::SocialAccount, :count)
        expect(error).to be_nil
      end
    end

    context 'when user was created before outside of facebook' do
      let!(:user) { create :user }
      let(:info) { { email: user.email, first_name: 'other', last_name: 'name' } }
      it 'creates a new social account for that user and logs him in' do
        expect { subject }.to do_not_change(User, :count).
          and change(User::SocialAccount, :count).by(1)
        expect(social_account.uid).to eq uid
        expect(social_account.provider).to eq provider
        expect(error).to be_nil
      end
    end

    context 'when user was created before by admin' do
      let!(:user) { create :user, :unconfirmed }
      let(:info) { user.attributes.slice('email', 'first_name', 'last_name') }

      it 'creates a social account and assigns it to him' do
        expect { subject }.to do_not_change(User, :count).
          and change(User::SocialAccount, :count)
        expect(error).to be_nil
        expect(social_account.uid).to eq uid
        expect(social_account.provider).to eq provider
      end

      it 'approves the user' do
        expect(returned_user).to be_confirmed
      end
    end

    context 'when failed to create social account' do
      let(:attributes) { returned_user.attributes }
      let(:info) { {first_name: 'John', last_name: 'Dorian', email: 'john@dorian.com', to_hash: 'a_hash'} }

      before do
        expect(User::SocialAccount).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(User.new))
      end

      it 'returns a fake user' do
        expect { subject }.to do_not_change(User, :count).
          and do_not_change(User::SocialAccount, :count)
        expect(error).to eql 'social_network_error'
        expect(returned_user.email).to eql 'john@dorian.com'
      end

      it 'sends notification to Rollbar' do
        expect(Rollbar).to receive(:error).with(
          instance_of(ActiveRecord::RecordInvalid),
          'Error while processing oauth2 callback from Facebook',
          {
            provider: 'facebook',
            uid: '12345678',
            info: 'a_hash',
            user: nil
          }
        )
        subject
      end
    end
  end
end
