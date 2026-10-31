class CheckoutController < ApplicationController
  before_action { @noindex = true }

  def new
    @lines = current_cart.detailed
    @total = current_cart.total
    @delivery = DeliveryOption.by_country
    track("checkout", "Checkout")
  end

  def create
    cart = current_cart
    if cart.empty?
      redirect_to checkout_path, alert: "Your cart is empty." and return
    end

    # Delivery: a country's delivery option adds its price (and can pay
    # online); "other" (or no options configured at all) is the pay-later flow
    # where the studio quotes delivery by hand.
    country = params[:country].to_s
    option = DeliveryOption.find_by(id: params[:delivery_option_id], country_code: country) if country.present?
    other = country == "other"
    if option.nil? && !other && DeliveryOption.exists?
      redirect_to checkout_path, alert: "Please choose your country and how you'd like it delivered." and return
    end
    online = Mypos.enabled? && option.present?

    # Where it goes: a street address, or a courier office in a city.
    kind = option&.kind || ("address" if other)
    f = ->(key) { params[key].to_s.strip }
    destination =
      case kind
      when "office"  then { city: f[:office_city], delivery_office: f[:office] }
      when "address" then { address_line: f[:address_line], city: f[:city], postal_code: f[:postal_code] }
      else {}
      end
    if destination.values.any?(&:blank?)
      redirect_to checkout_path, alert: (kind == "office" ? "Please tell us which courier office to deliver to." : "Please fill in your delivery address.") and return
    end

    order = nil
    Order.transaction do
      order = Order.new(
        number: Order.next_number, status: "new",
        payment_status: online ? "pending" : "none",
        country_code: option&.country_code,
        country_name: option&.country_name || (f[:country_other].presence if other),
        delivery_cost: option&.cost,
        delivery_option_name: option&.name,
        delivery_kind: kind,
        **destination,
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
      order.total = total + option&.cost.to_i
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
