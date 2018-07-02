class Admin::Venues::Groups::MembersController < Admin::BaseController
  around_action :use_timezone

  def index
    @members = authorized_scope(group.members).
                             includes(:user).
                             order(:created_at).
                             paginate(page: params[:page])
  end

  def show
    member
  end

  def create
    @member = authorize group.members.build(create_params)

    if @member.save
      render 'show', status: :created
    else
      render json: { errors: @member.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if member.destroy
      render json: [member.id]
    else
      head :unprocessable_entity
    end
  end

  def destroy_many
    deleted = many_members.select do |member|
      member.destroy
    end

    render json: deleted.map(&:id)
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

  def many_members
    @many_members ||= authorized_scope(group.members).
                        where(id: params[:member_ids])
  end

  def create_params
    params.require(:member).permit(:user_id)
  end
end
