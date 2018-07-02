module API
  # handles user credit cards actions
  class CardsController < API::BaseController
    before_action :authenticate_request!
    def index
    end

    def create
      if @current_user.has_stripe?
        @current_user.add_card(params[:token])
      else
        @current_user.add_stripe_id(params[:token])
      end
      #SegmentAnalytics.credit_card(@current_user)
      #todo CHECK IT WAS SUCCESSFUL
      render template: "api/cards/index.json.jbuilder"
    end

    def destroy
      if @current_user.destroy_card(params[:token])
        render 'index'
      else
        render json: { errors: I18n.t('activerecord.errors.models.credit_cards.cannot_destroy') },
          status: :unprocessable_entity
      end
    end
  end
end
