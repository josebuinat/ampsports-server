class API::DevicesController < API::BaseController
  before_action :authenticate_request!

  def create
    @device = @current_user.devices.build(device_params)
    if @device.save
      head :ok
    else
      head 400
    end
  end

  def destroy
    token = request.headers['device_token']
    @current_user.devices.find_by(token: token).destroy if token
    head :ok
  end

  private

  def device_params
    params.require(:device).permit(:token)
  end
end
