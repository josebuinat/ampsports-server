class Admin::Venues::Emails::ListsController < Admin::BaseController
  def index
    @lists = authorized_scope(venue.email_lists)
  end

  def update
    if list.update(update_params)
      render 'show'
    else
      render json: { errors: list.errors }, status: :unprocessable_entity
    end
  end

  def create
    # cannot use venue.email_lists.build here, as it would not associate it with the venue
    @list = authorize venue.email_lists.create(create_params)
    if @list.persisted?
      render 'show', status: :created
    else
      render json: { errors: list.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    list.destroy
    render json: [list.id]
  end

  def select_options
    @lists = authorized_scope(venue.email_lists)
    options = @lists.map do |list|
      { value: list.id, label: list.name }
    end
    render json: options
  end

  protected

  def update_params
    params.require(:list).permit(:name)
  end

  def create_params
    update_params
  end

  def list
    @list ||= authorized_scope(venue.email_lists).find(params[:id])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end