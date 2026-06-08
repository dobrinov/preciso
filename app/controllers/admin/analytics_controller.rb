module Admin
  class AnalyticsController < BaseController
    def index
      @range = params[:range].presence_in(%w[7d 30d all]) || "7d"
      @from = case @range
              when "7d" then 7.days.ago
              when "30d" then 30.days.ago
              else Time.at(0)
              end
      @days = @range == "7d" ? 7 : 30

      @summary = Event.summary(@from)
      @daily = Event.daily(@days)
      @top_pages = Event.top_pages(@from, 6)
      @top_pieces = Event.top_pieces(@from, 6)
      @recent = Event.recent(16)
      @max_day = [1, *@daily.map { |d| d[:views] }].max
    end

    def reset
      Event.delete_all
      redirect_to admin_analytics_path
    end
  end
end
