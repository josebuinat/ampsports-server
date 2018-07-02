class Admin::Venues::Groups::EmailsController < Admin::BaseController

  def create
    authorize CustomMail

    @custom_email = venue.custom_mails.create(create_params)

    if @custom_email.persisted?
      @custom_email.send_test_mail(current_admin.email) if send_copy?
      head :created
    else
      render json: { errors: @custom_email.errors }, status: :unprocessable_entity
    end
  end

  private

  def company
    current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def group
    @group ||= venue.groups.find(params[:group_id])
  end

  def member
    @member ||= authorized_scope(group.members).find(params[:id])
  end

  def create_params
    params.require(:custom_email).permit(:body, :subject, :from, :image).merge(
      recipient_users: group.users.pluck(:email).join(',')
    )
  end

  def send_copy?
    params.dig(:custom_email, :send_copy)
  end

end
