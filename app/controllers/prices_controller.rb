# Handles price actions
class PricesController < ApplicationController
  before_action :set_venue
  before_action :set_price, only: [:show, :update, :destroy]
  around_action :use_timezone

  def show
    @price = Price.find(params[:id])
    @venue = Venue.find(params[:venue_id])
  end

  def create
    @price = Price.new(price_params)
    if @price.save
      conflicts = []
      court_conflicts = {}

      courts.each do |c|
        div = Divider.new(price: @price, court: c)
        unless div.save
          conflicts << div.conflict_prices
          div.conflict_prices.each do |p|
            court_conflicts[p.id] ||= []
            court_conflicts[p.id] << c.id
          end
        end
      end

      if conflicts.any?
        @price.destroy
        @conflicts = conflicts.flatten.uniq
        @courts = courts
        @court_conflicts = court_conflicts

        render partial: 'venues/prices_modal', locals: {conflicts: @conflicts}, status: :unprocessable_entity
      else
        render partial: 'prices/price', locals: { venue: @venue, price: @price }, status: :ok
      end
    else
      render json: @price, status: :unprocessable_entity
    end
  end

  def merge_conflicts
    @price = Price.find(params[:id])
    params[:conflicts].each_pair do |price_id, court_ids|
      price = Price.find(price_id)
      courts = court_ids.map { |id| Court.find(id) }
      price.merge_price!(@price, *courts)
    end

    redirect_to :back, notice: 'All the conflicts were resolved'
  end

  def update
    @errors, @conflicts = @price.update_or_find_conflicts(price_params,
                                                          params[:court_ids])
    if @conflicts then render partial: 'venues/prices_modal',
                              locals: { conflicts: @conflicts }, status: :unprocessable_entity
    elsif !@errors then render partial: 'prices/price',
                               locals: { venue: @venue, price: @price },
                               status: :ok
    else
      render json: @errors, status: 406
    end
  end

  def destroy
    @price.destroy!
    render json: @price, status: :ok
  end

  private

  def set_venue
    @venue = Venue.find(params[:venue_id])
  end

  def use_timezone
    Time.use_zone(@venue.timezone) { yield }
  end

  def set_price
    @price = Price.find(params[:id])
  end

  def price_params
    permittable = [:price, :start_time, :end_time] + Price::WEEKDAYS
    params.require(:price).permit(*permittable)
  end

  def courts
    Court.where(id: params[:court_ids], venue: @venue)
  end
end
