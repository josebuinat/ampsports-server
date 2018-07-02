class Admin::Companies::ActivityLogsController < Admin::BaseController
  def index
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10
    search_args = JSON.parse(params[:search] || '{}').symbolize_keys
    @activity_logs = authorized_scope(company.activity_logs).
                            merge(ActivityLog.search(search_args)).
                            includes(:activity_logs_payloads_connectors).
                            order(created_at: :desc).
                            page(params[:page]).
                            per_page(per_page)
  end

  private

  def company
    @company ||= current_admin.company
  end
end
