class Admin::Reservations::LogsController < Admin::BaseController
  around_action :use_timezone

  def index
    @logs = authorized_scope(reservation.logs).includes(reservation: :court)
  end

  private

  def reservation
    @reservation ||= company.reservations.find(params[:reservation_id])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= reservation.venue
  end
end
