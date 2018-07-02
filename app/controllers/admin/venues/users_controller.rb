class Admin::Venues::UsersController < Admin::BaseController
  def import
    authorize User

    @importer = CSVImportUsers.new(params[:csv_file], venue).run

    if @importer.valid?
      render status: :created
    else
      render json: { errors: @importer.errors }, status: :unprocessable_entity
    end
  end

  private

  def company
    @company ||= current_admin.company
  end

  # empty venue_id error handled by @importer
  def venue
    @venue = params[:venue_id] && company.venues.find(params[:venue_id])
  end
end
