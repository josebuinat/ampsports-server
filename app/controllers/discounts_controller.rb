# Handles actions affecting discounts models
class DiscountsController < ApplicationController
  authorize_resource

  def index
    venue = Venue.find(params[:venue_id])
    render json: venue.discounts
  end


  def destroy
    discount = Discount.find(params[:id]).destroy
    render json: discount
  end

  private

  def discount_params
    params.require(:discount).permit(:name, :value, :method, :round)
  end
end
