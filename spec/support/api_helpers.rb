def sign_in_for_api_with(user, token: 'SECRETTOKEN')
  @request.headers.merge!({ 'Authorization' => "Bearer #{token}"})
  allow(AuthToken).to receive(:decode).with(token, any_args).and_return({id: user.id, type: user.class.name})
end
