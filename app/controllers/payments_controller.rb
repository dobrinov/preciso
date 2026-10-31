# myPOS Checkout endpoints. See app/models/mypos.rb for the protocol.
class PaymentsController < ApplicationController
  # myPOS posts to these from its own domain — there is no Rails CSRF token.
  # notify is authenticated by its RSA signature instead; ok/cancel change
  # nothing that matters (see below).
  skip_forgery_protection only: [ :notify, :ok, :cancel ]
  before_action { @noindex = true }

  # Auto-submitting form that sends the customer to the myPOS payment page.
  def pay
    @order = Order.find_by!(number: params[:number])
    return redirect_to(checkout_confirmation_path(@order.number)) unless @order.awaiting_payment?

    @action = Mypos.endpoint
    @fields = Mypos.purchase_params(
      @order,
      ok_url: mypos_ok_url(@order.number),
      cancel_url: mypos_cancel_url(@order.number),
      notify_url: mypos_notify_url
    )
  end

  # Server-to-server call from myPOS. The ONLY place an order becomes paid.
  # Must answer 200 "OK"; anything else makes myPOS treat it as failed (and
  # reverse the payment), which is what we want when we can't verify it.
  def notify
    pairs = URI.decode_www_form(request.raw_post)
    data = pairs.to_h

    unless Mypos.valid_signature?(pairs)
      Rails.logger.warn("myPOS notify: bad signature (#{data['IPCmethod']} #{data['OrderID']})")
      return head(:bad_request)
    end

    order = Order.find_by(number: data["OrderID"])
    return head(:not_found) unless order

    case data["IPCmethod"]
    when "IPCPurchaseNotify"
      if data["Amount"].to_d != order.total.to_d || data["Currency"].to_s.upcase != Mypos.currency
        Rails.logger.error("myPOS notify: amount/currency mismatch for #{order.number}: #{data['Amount']} #{data['Currency']}")
        return head(:unprocessable_entity)
      end
      order.update!(
        payment_status: "paid", paid_at: Time.current,
        payment_reference: data["IPC_Trnref"],
        payment_details: [ data["PaymentMethod"], data["CardBrand"], data["PAN"] ].compact_blank.join(" · ").presence
      )
    when "IPCPurchaseRollback"
      # myPOS reversed a payment (e.g. our notify answer didn't reach it).
      order.update!(payment_status: "failed", paid_at: nil)
    else
      Rails.logger.info("myPOS notify: ignoring #{data['IPCmethod']} for #{order.number}")
    end

    render plain: "OK"
  end

  # Customer's browser returning from a successful payment. myPOS POSTs here
  # cross-site, so the session cookie (SameSite=Lax) isn't sent: bounce to a
  # GET of the same URL, which does carry it, then clear the cart.
  def ok
    return redirect_to(mypos_ok_path(params[:number]), status: :see_other) if request.post?

    order = Order.find_by!(number: params[:number])
    current_cart.clear
    record_order_event(order)
    redirect_to checkout_confirmation_path(order.number)
  end

  # Customer cancelled on the payment page. The cart is still in the session, so
  # they land back on checkout and can try again (a fresh order is created).
  def cancel
    return redirect_to(mypos_cancel_path(params[:number]), status: :see_other) if request.post?

    order = Order.find_by!(number: params[:number])
    order.update!(payment_status: "failed") if order.awaiting_payment?
    redirect_to checkout_path, alert: "Payment was cancelled — nothing was charged. Your cart is still here."
  end
end
