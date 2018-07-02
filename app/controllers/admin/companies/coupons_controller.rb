class Admin::Companies::CouponsController < Admin::BaseController
  skip_before_action :authenticate_request!

  def show
    if coupon
      render json: { description: coupon.description, code: coupon.code }
    else
      head :not_found
    end
  end

  private

  def coupon
    @coupon ||= Coupon.find_by code: params[:code]&.downcase
  end
end