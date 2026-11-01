# Builds and sends one order email, recording the outcome on its EmailLog.
class OrderEmailJob < ApplicationJob
  queue_as :default

  def perform(log_id)
    log = EmailLog.find_by(id: log_id) or return
    order = log.order or return log.update!(status: "failed", detail: "Order no longer exists")

    mail = OrderMailer.public_send(log.kind, order)
    log.update!(recipient: Array(mail.to).join(", "), subject: mail.subject)
    mail.deliver_now
    log.update!(status: "sent", detail: nil)
  rescue => e
    Rails.logger.error("order email #{log_id} failed: #{e.class}: #{e.message}")
    log&.update_columns(status: "failed", detail: "#{e.class}: #{e.message}".truncate(250), updated_at: Time.current)
  end
end
