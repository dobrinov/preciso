module Admin
  class OrdersController < BaseController
    def index
      # Checkouts that never got paid (myPOS) live under their own "unpaid" tab
      # so they don't clutter the real order list.
      @filter = params[:filter].presence_in([ "all" ] + Order::STATUS_ORDER + [ "unpaid" ]) || "all"
      @orders =
        case @filter
        when "all" then Order.placed
        when "unpaid" then Order.unpaid
        else Order.placed.where(status: @filter)
        end
      @counts = { "all" => Order.placed.count, "unpaid" => Order.unpaid.count }
      Order::STATUS_ORDER.each { |s| @counts[s] = Order.placed.where(status: s).count }
    end

    def show
      @order = Order.find_by!(number: params[:number])
    end

    def update
      @order = Order.find_by!(number: params[:number])
      @order.update(status: params[:status]) if Order::STATUS_ORDER.include?(params[:status])
      redirect_to admin_order_path(@order)
    end

    def destroy
      Order.find_by!(number: params[:number]).destroy
      redirect_to admin_orders_path
    end
  end
end
