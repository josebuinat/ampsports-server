module Imageable
  def upload_photo
    @current_user.update(photo: params[:photo])
    render json: @current_user.authentication_payload, status: :ok
  end
end
