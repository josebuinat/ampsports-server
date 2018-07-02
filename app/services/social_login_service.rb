class SocialLoginService
  class << self
    def from_omniauth(auth)
      email = auth.info.email&.downcase

      # do not allow anyone without email
      return ['social_network_error', fake_user_from_auth(auth)] if email.blank?

      user = User.find_by(email: email)

      if user
        # if devise/confirm_within would be set up we would have to reset confirmation_sent_at
        user.confirm unless user.confirmed?
      end
      social_account = create_social_account(user, auth) if need_to_create_social_account?(user, auth)
      user ||= social_account.user

      [nil, user]
    rescue StandardError => e
      Rollbar.error(e, 'Error while processing oauth2 callback from Facebook',
                    provider: auth.provider,
                    uid: auth.uid,
                    info: auth.info.to_hash,
                    user: user
      )
      ['social_network_error', user || fake_user_from_auth(auth)]
    end

    # Create a social login if this is sign up via FB or
    # sign in via FB and current user has no social login.
    def need_to_create_social_account?(user, auth)
      return true unless user
      user.has_social_account?(auth.provider, auth.uid) ? false : true
    end

    # If we have user record - use it, otherwise create a new one, setting fields with data
    # returned by FB, random password and skip confimation for that user.
    def create_social_account(user, auth)
      user ||= User.new do |user|
        info = auth.info
        user.first_name = info.first_name
        user.last_name = info.last_name
        user.email = info.email
        user.image = info.image
        user.password = user.password_confirmation = Devise.friendly_token[0, 20]
        user.skip_confirmation!
      end

      User::SocialAccount.create!(provider: auth.provider, uid: auth.uid, user: user)
    end

    def fake_user_from_auth(auth)
      OpenStruct.new(id: auth.uid, email: auth.info.email)
    end
  end
end
