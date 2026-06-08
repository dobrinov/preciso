module Admin
  class OrdersController < BaseController
    def index
      @filter = params[:filter].presence_in(["all"] + Order::STATUS_ORDER) || "all"
      @orders = @filter == "all" ? Order.all : Order.where(status: @filter)
      @counts = { "all" => Order.count }
      Order::STATUS_ORDER.each { |s| @counts[s] = Order.where(status: s).count }
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
