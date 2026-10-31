class CheckoutController < ApplicationController
  before_action { @noindex = true }

  def new
    @lines = current_cart.detailed
    @total = current_cart.total
    @rates = DeliveryRate.sorted
    track("checkout", "Checkout")
  end

  def create
    cart = current_cart
    if cart.empty?
      redirect_to checkout_path, alert: "Your cart is empty." and return
    end

    # Delivery: a country with a fixed rate gets that price added (and can pay
    # online); "other" (or no rates configured at all) is the pay-later flow
    # where the studio quotes delivery by hand.
    rate = DeliveryRate.find_by(country_code: params[:country].to_s)
    if rate.nil? && params[:country] != "other" && DeliveryRate.exists?
      redirect_to checkout_path, alert: "Please choose the country we're delivering to." and return
    end
    online = Mypos.enabled? && rate.present?

    # Anything delivered needs an address.
    delivering = rate.present? || params[:country] == "other"
    address = params.values_at(:address_line, :city, :postal_code).map { |v| v.to_s.strip }
    if delivering && address.any?(&:blank?)
      redirect_to checkout_path, alert: "Please fill in your delivery address." and return
    end

    order = nil
    Order.transaction do
      order = Order.new(
        number: Order.next_number, status: "new",
        payment_status: online ? "pending" : "none",
        country_code: rate&.country_code,
        country_name: rate&.name || params[:country_other].to_s.strip.presence,
        delivery_cost: rate&.cost,
        address_line: (address[0] if delivering),
        city: (address[1] if delivering),
        postal_code: (address[2] if delivering),
        customer_name: params[:name].to_s.strip,
        customer_email: params[:email].to_s.strip,
        customer_phone: params[:phone].to_s.strip,
        note: params[:note].to_s.strip
      )
      total = 0
      lines = cart.detailed.map do |l|
        total += l.subtotal
        { kind: l.kind, item_id: l.id, name: l.record.name, price: l.unit_price, qty: l.qty,
          variant_id: l.variant&.id, variant_label: l.variant&.label }
      end
      order.total = total + rate&.cost.to_i
      order.save!
      lines.each { |attrs| order.order_lines.create!(attrs) }
    end

    # With myPOS on, the cart is kept until the customer comes back from a
    # successful payment (they may cancel and want to try again).
    if order.awaiting_payment?
      redirect_to checkout_pay_path(order.number) and return
    end

    record_order_event(order)
    Notifier.order_placed(order)
    cart.clear

    redirect_to checkout_confirmation_path(order.number)
  end

  def confirmation
    @order = Order.find_by!(number: params[:number])
  end
end
