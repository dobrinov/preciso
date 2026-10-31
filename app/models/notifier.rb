# Sends the order emails. Every method is fire-and-forget: mail goes out in
# the background, and a failure to send is logged, never raised — an email
# problem must not break checkout or the myPOS payment callback.
#
# Emails are sent only when an SMTP server is configured (SMTP_ADDRESS etc.,
# see config/environments/production.rb).
module Notifier
  module_function

  def configured? = ActionMailer::Base.perform_deliveries

  def studio_email = NotificationSetting.instance.studio_email.presence

  # Order placed without online payment (pay-later flow).
  def order_placed(order)
    deliver { OrderMailer.received(order) }
    deliver { OrderMailer.studio_new_order(order) } if studio_email
  end

  # myPOS confirmed the card payment.
  def order_paid(order)
    deliver { OrderMailer.paid(order) }
    deliver { OrderMailer.studio_new_order(order) } if studio_email
  end

  # Studio changed the status in admin.
  def status_changed(order)
    return unless OrderMailer::STATUS_EMAILS.include?(order.status)
    deliver { OrderMailer.status_changed(order) }
  end

  def deliver
    return unless configured?
    yield.deliver_later
  rescue => e
    Rails.logger.error("email not sent: #{e.class}: #{e.message}")
  end
end
