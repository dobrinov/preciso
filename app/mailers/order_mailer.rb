class OrderMailer < ApplicationMailer
  # Statuses that trigger an email to the customer when set in admin.
  STATUS_EMAILS = %w[preparing fulfilled cancelled].freeze

  # Customer: order placed without online payment.
  def received(order)
    @order = order
    customer_mail "We've received your order #{order.number}"
  end

  # Customer: card payment confirmed by myPOS.
  def paid(order)
    @order = order
    customer_mail "Payment received — order #{order.number}"
  end

  # Customer: status changed by the studio.
  def status_changed(order)
    @order = order
    subject = {
      "preparing" => "Your order #{order.number} is being prepared",
      "fulfilled" => "Your order #{order.number} is on its way",
      "cancelled" => "Your order #{order.number} was cancelled"
    }[order.status]
    customer_mail subject
  end

  # Studio: a new order to handle (paid online, or pay-later).
  def studio_new_order(order)
    @order = order
    @studio = true # layout: compact header/footer
    label = order.paid? ? "paid" : "payment to arrange"
    mail to: NotificationSetting.instance.studio_email, reply_to: order.customer_email,
         subject: "New order #{order.number} — #{ApplicationHelper::CURRENCY}#{order.total} (#{label})"
  end

  # Admin "send test email" button.
  def test_message(to)
    mail to: to, subject: "Preciso test email" do |format|
      format.text { render plain: "Email sending from the Preciso shop works." }
    end
  end

  private

  def customer_mail(subject)
    mail to: @order.customer_email, subject: subject,
         reply_to: NotificationSetting.instance.studio_email.presence
  end
end
