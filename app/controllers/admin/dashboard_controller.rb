module Admin
  class DashboardController < BaseController
    def index
      @orders = Order.placed
      @revenue = Order.placed.active.sum(:total)
      @new_count = Order.placed.where(status: "new").count
      @prep_count = Order.placed.where(status: "preparing").count
      @recent = Order.placed.limit(5)

      # best sellers by units across all order lines
      tally = Hash.new(0)
      OrderLine.where(order_id: Order.placed.select(:id)).find_each { |l| tally[l.name] += l.qty }
      @best = tally.sort_by { |_, q| -q }.first(5)
      @max_best = @best.first&.last || 1
    end
  end
end
