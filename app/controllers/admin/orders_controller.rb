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
      if Order::STATUS_ORDER.include?(params[:status]) && params[:status] != @order.status
        @order.update(status: params[:status])
        # Cancelling puts ready-to-ship pieces back on the shelf; reopening a
        # placed order takes them off again.
        if @order.status == "cancelled"
          @order.return_stock!
        elsif @order.payment_status.in?(%w[none paid])
          @order.take_stock!
        end
        Notifier.status_changed(@order)
      end
      redirect_to admin_order_path(@order)
    end

    # The studio checked it can deliver (typically abroad, with no set delivery
    # rate): fix the delivery cost and email the customer a link to pay by card.
    def send_payment_link
      order = Order.find_by!(number: params[:number])
      cost = params[:delivery_cost].to_s.strip
      if !order.payment_link_possible?
        notice = "This order can't take a payment link."
      elsif !Mypos.enabled?
        notice = "Turn on card payments first (Admin → Payments)."
      elsif cost !~ /\A\d+\z/
        notice = "Enter the delivery cost in whole euros (0 if free)."
      else
        order.confirm_for_payment!(delivery_cost: cost.to_i, note: params[:quote_note].to_s.strip)
        log = Notifier.deliver(order, "payment_link")
        notice = log&.status == "queued" ? "Payment link emailed to #{order.customer_email}" : "Saved, but the email wasn't sent: #{log&.detail || "unknown error"}"
      end
      redirect_to admin_order_path(order), flash: { link_notice: notice }
    end

    # Send one of the order's emails again (e.g. the customer can't find it).
    def resend_email
      order = Order.find_by!(number: params[:number])
      kind = params[:kind].presence_in(EmailLog::KINDS.keys)
      log = kind && Notifier.deliver(order, kind)
      notice = log&.status == "queued" ? "#{log.label} email is being sent again" : "Not sent: #{log&.detail || "unknown email"}"
      redirect_to admin_order_path(order), notice: notice
    end

    def destroy
      Order.find_by!(number: params[:number]).destroy
      redirect_to admin_orders_path
    end
  end
end
