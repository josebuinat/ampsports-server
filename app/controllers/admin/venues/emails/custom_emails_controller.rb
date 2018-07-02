class Admin::Venues::Emails::CustomEmailsController < Admin::BaseController
  def index
    @custom_mails = authorized_scope(venue.custom_mails).
                          includes(:users).
                          search(params[:search_term]).
                          order(created_at: :desc)
  end

  def create
    authorize CustomMail

    @custom_mail = venue.custom_mails.create(create_params)

    if @custom_mail.persisted?
      @custom_mail.send_test_mail(current_admin.email) if send_copy?
      render json: { message: t('.success') }, status: :created
    else
      render json: { errors: @custom_mail.errors }, status: :unprocessable_entity
    end

  end

  private

  def send_copy?
    params.dig(:custom_email, :send_copy)
  end

  def valid_group_ids
    to_groups = params.dig(:custom_email, :to_groups)
    # can be either hash (need only values), either array
    to_groups = to_groups.values if to_groups.is_a?(Hash)
    venue.email_lists.where(id: [*to_groups].map(&:to_i)).pluck(:id)
  end

  def create_params
    params.require(:custom_email).permit(:body, :subject, :from, :to_users, :image).
        merge(to_groups: valid_group_ids).permit!
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end