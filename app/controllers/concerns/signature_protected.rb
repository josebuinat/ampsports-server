module SignatureProtected
  extend ActiveSupport::Concern

  included do
    before_action :safe_validate_request_signature

    class InvalidRequestSignature < StandardError; end
    rescue_from InvalidRequestSignature, with: :invalid_request_signature

    def safe_validate_request_signature
      begin
        validate_request_signature
      rescue InvalidRequestSignature
        signature = request.headers['signature']
        app_name = request.headers['app-name']
        client_no_query_string_pathname = request.headers['no-query-string-pathname']
        client_secret = request.headers['signature-secret']
        if signature.blank?
          Rollbar.error('Missing request signature (client did not provide a `signature` header')
        elsif app_name.blank?
          Rollbar.error('Missing request signature app name (client did not provide a `app-name` header')
        else
          Rollbar.error("Invalid request signature (full info)",
            received_signature: signature,
            expected_signature: (RequestSignatureCalculator.(request, app_name) rescue 'error-calculating'),
            app_name: app_name,
            path: request.fullpath,
            client_no_query_string_pathname: client_no_query_string_pathname,
            server_no_query_string_pathname: request.fullpath.split('?').first,
            client_secret: client_secret,
            server_secret: APISecretKey.find_by(name: app_name)&.key,
            onewordtest: request.headers['oneword']
          )
        end
      end
    end

    # Check that api request is done via authorised app, not by some random dude
    # Essentially we check "signature" request header with the one we calculate ourselves
    # Each request has it's own signature! Basically, signature is md5(request body + salt)
    def validate_request_signature
      # Sometimes we don't want to check request signature and trust it (e.g. in test mode)
      return true unless Rails.configuration.x.perform_request_signature_validation
      received_signature = request.headers['signature']
      app_name = request.headers['app-name']
      expected_signature = begin
        RequestSignatureCalculator.(request, app_name)
      rescue ActiveRecord::RecordNotFound
        raise InvalidRequestSignature
      end

      raise InvalidRequestSignature if received_signature != expected_signature
      true
    end

    def invalid_request_signature
      render json: { errors: [I18n.t('api.authentication.invalid_signature')] }, status: :precondition_failed
    end

  end
end
