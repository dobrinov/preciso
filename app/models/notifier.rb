# Sends the order emails. Every method is fire-and-forget: mail goes out in
# the background (OrderEmailJob), and a failure to send is recorded on the
# order's EmailLog and logged, never raised — an email problem must not break
# checkout or the myPOS payment callback.
#
# Emails are sent only when an SMTP server is configured (SMTP_ADDRESS etc.,
# see config/environments/production.rb); otherwise the attempt is recorded
# as skipped, so admin shows why nothing went out.
module Notifier
  module_function

  def configured? = ActionMailer::Base.perform_deliveries

  def studio_email = NotificationSetting.instance.studio_email.presence

  # Order placed without online payment (pay-later flow).
  def order_placed(order)
    deliver(order, "received")
    deliver(order, "studio_new_order")
  end

  # myPOS confirmed the card payment.
  def order_paid(order)
    deliver(order, "paid")
    deliver(order, "studio_new_order")
  end

  # Studio changed the status in admin.
  def status_changed(order)
    return unless OrderMailer::STATUS_EMAILS.include?(order.status)
    deliver(order, "status_changed")
  end

  def deliver(order, kind)
    skip = if !configured? then "Email sending isn't set up on the server"
    elsif kind == "studio_new_order" && !studio_email then "No address set in Admin → Emails"
    end
    log = EmailLog.create!(order: order, kind: kind, status: skip ? "skipped" : "queued", detail: skip,
                           recipient: (kind == "studio_new_order" ? studio_email : order.customer_email))
    OrderEmailJob.perform_later(log.id) unless skip
    log
  rescue => e
    Rails.logger.error("email not sent: #{e.class}: #{e.message}")
    nil
  end
end
