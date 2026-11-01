module Admin
  class AnalyticsController < BaseController
    RANGES = { "7d" => "7 days", "30d" => "30 days", "90d" => "90 days", "all" => "All" }.freeze
    PER_PAGE = 50

    before_action :load_report, except: :reset

    def index
      @summary = @report.summary
      @funnel = @report.purchase_funnel
      @daily = @report.daily
      @sources = @report.by_source.first(8)
      @pieces = @report.pieces(8)
      @latest = @report.journeys.sort_by(&:last_at).reverse.first(8)
    end

    def visitors
      @outcome = params[:outcome].presence_in(Analytics::Journey::OUTCOMES.keys.map(&:to_s))
      @source = params[:source].presence
      @device = params[:device].presence
      @q = params[:q].to_s.strip
      @show_hidden = params[:hidden] == "1"

      base = @show_hidden ? @report.hidden : @report.journeys
      @counts = Analytics::Journey::OUTCOMES.keys.index_with { |k| base.count { |j| j.depth == k } }
      list = base
      list = list.select { |j| j.depth.to_s == @outcome } if @outcome
      list = list.select { |j| j.source == @source } if @source
      list = list.select { |j| j.device == @device } if @device
      if @q.present?
        needle = @q.downcase
        list = list.select do |j|
          j.sid.downcase.include?(needle) || j.label.downcase.include?(needle) ||
            j.events.any? { |e| e.label.to_s.downcase.include?(needle) }
        end
      end
      list = list.sort_by(&:last_at).reverse
      @total = list.size
      @page = [ params[:page].to_i, 1 ].max
      @visitors = list.slice((@page - 1) * PER_PAGE, PER_PAGE) || []
      @pages = (@total / PER_PAGE.to_f).ceil
    end

    def visitor
      @journey = @report.find(params[:sid]) or raise ActiveRecord::RecordNotFound
      @orders = Order.where(number: @journey.order_numbers).index_by(&:number)
    end

    def funnels
      @kind = params[:funnel].presence_in(%w[purchase checkout source]) || "purchase"
      @source = params[:source].presence || @report.by_source.first&.dig(:name)
      @steps =
        case @kind
        when "checkout" then @report.checkout_funnel
        when "source" then @report.source_funnel(@source)
        else @report.purchase_funnel
        end
      @purchase = @report.purchase_funnel
      @checkout = @report.checkout_funnel
      @by_source = @report.by_source
      @by_device = @report.by_device
    end

    def reset
      Event.delete_all
      redirect_to admin_analytics_path
    end

    private

    def load_report
      @range = params[:range].presence_in(RANGES.keys) || "30d"
      from = case @range
      when "7d" then 7.days.ago
      when "30d" then 30.days.ago
      when "90d" then 90.days.ago
      else Event.minimum(:occurred_at) || 30.days.ago
      end
      @report = Analytics::Report.new(from:)
    end
  end
end
