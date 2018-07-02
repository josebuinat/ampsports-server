class RequestSignatureCalculator
  # used to secure our API from unauthorized usage of 3rd parties
  def self.call(request, app_name)
    new(request, app_name).call
  end

  def initialize(request, app_name)
    @request = request
    @app_name = app_name
  end

  # returns calculates signature for given request / app pair;
  # signature is an md5(request body + salt)
  def call
    secret_token = APISecretKey.find_by!(name: @app_name).key
    path = @request.fullpath.split('?').first
    Digest::MD5.hexdigest(path + secret_token)
  end
end