class Admin::Companies::CoachesController < Admin::BaseController
  def index
    if params[:with_outstanding_balance].present?
      ob = OutstandingBalances.new(company)
      @outstanding_balances = ob.coach_outstanding_balances
      @coaches = ob.all_coaches
    else
      @coaches = company.coaches
    end

    @coaches = authorized_scope(@coaches)
    @coaches = @coaches.search(params[:search]) if params[:search].present?
    @coaches = @coaches.sort_on(params[:sort_on]) if params[:sort_on].present?
    @coaches = @coaches.paginate(page: params[:page], per_page: 5)
  end

  def show
    coach
  end

  def create
    @coach = authorize company.coaches.build(create_params)

    if @coach.save
      render 'show', status: :created
    else
      render json: { errors: @coach.errors }, status: :unprocessable_entity
    end
  end

  def update
    updating_password = Coach.password_fields.any? { |x| update_params[x].present? }
    method = updating_password ? :update_with_password : :update_without_password

    if coach.public_send(method, update_params)
      render 'show'
    else
      render json: { errors: coach.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    coach.destroy

    render json: [coach.id]
  end

  def destroy_many
    deleted = many_coaches.select do |coach|
      coach.destroy
    end

    render json: deleted.map(&:id)
  end

  def select_options
    render json: authorized_scope(company.coaches).
                    map { |coach| { value: coach.id, label: coach.full_name } }
  end

  private

  def coach
    @coach ||= authorized_scope(company.coaches).find(params[:id])
  end

  def many_coaches
    @many_coaches ||= authorized_scope(company.coaches).where(id: params[:coach_ids])
  end

  def update_params
    record = coach rescue Coach
    params.require(:coach).permit(policy(record).permitted_attributes)
  end

  def create_params
    update_params.merge(without_password: true, locale: I18n.locale)
  end

  def company
    @company ||= current_admin.company
  end
end
