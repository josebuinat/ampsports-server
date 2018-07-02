# Endpoints related to venue reviews
class API::ReviewsController < API::BaseController
  before_filter :authenticate_request!, except: [:index]
  before_filter :set_review, only: [:update, :destroy]

  rescue_from ActionController::ParameterMissing, with: :review_missing

  def index
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10

    @reviews = venue.reviews.includes(:author).
                             order(created_at: :desc).
                             page(params[:page]).
                             per_page(per_page)
  end

  def create
    @review = reviews.where(author: current_user).first ||
                reviews.new(author: current_user)
    handle_save
  end

  def update
    handle_save
  end

  def destroy
    @review.destroy
    render json: { message: I18n.t('api.reviews.deleted') }, status: :ok
  end

  private

  def handle_save
    @review.assign_attributes(review_params)
    success_status = @review.new_record? ? :created : :ok
    if @review.save
      render json: @review.as_json, status: success_status
    else
      render json: @review.errors.full_messages, status: :unprocessable_entity
    end
  end

  def review_params
    params.require(:review).permit(:rating, :text)
  end

  def venue
    @venue ||= Venue.find(params[:venue_id])
  end

  def reviews
    @reviews ||= venue.reviews
  end

  def set_review
    @review = reviews.find(params[:id])
    if @review.author.id != current_user.id
      render json: { errors: [I18n.t('api.reviews.unauthorized')] },
             status: :unauthorized
    end
  end

  def review_missing
    render json: { errors: [I18n.t('api.reviews.empty')] },
           status: :unprocessable_entity
  end
end
