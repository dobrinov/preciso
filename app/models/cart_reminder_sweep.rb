# Sends the cart reminders that are due. Runs in a background job, kicked off
# at most every few minutes by ordinary site traffic (see ApplicationController)
# and on demand from Admin → Cart reminders. All state is in the database, so
# nothing is lost when the server restarts.
module CartReminderSweep
  module_function

  INTERVAL = 5.minutes
  STALE_AFTER = 7.days      # don't send a reminder that is this far overdue
  ONE_PER = 30.days         # at most one reminder per address in this window

  @last_kick = nil
  @lock = Mutex.new

  # Cheap, throttled trigger called after storefront requests.
  def kick
    @lock.synchronize do
      return if @last_kick && @last_kick > INTERVAL.ago
      @last_kick = Time.current
    end
    CartReminderJob.perform_later
  end

  def run
    setting = CartReminderSetting.instance
    return 0 unless setting.enabled
    sent = 0
    CartReminder.due.find_each do |r|
      outcome = deliver(r, setting)
      sent += 1 if outcome == "sent"
    end
    sent
  end

  def deliver(r, setting)
    reason =
      if CartReminder.unsubscribed?(r.email) then "Address unsubscribed"
      elsif r.ordered_since? then nil.tap { r.update!(status: "converted", detail: "Ordered before the reminder was due") }
      elsif r.send_at < STALE_AFTER.ago then "Too late to send (reminders were switched off)"
      elsif CartReminder.where("lower(email) = ?", r.email.downcase).where.not(id: r.id).where("sent_at > ?", ONE_PER.ago).exists?
        "Already reminded in the last #{ONE_PER.in_days.to_i} days"
      elsif r.lines.empty? then "The pieces are no longer in the shop"
      elsif r.cart_total < setting.min_cart_total then "Cart below the minimum total"
      elsif !Notifier.configured? then "Email sending isn't set up on the server"
      end
    return r.status if r.status == "converted"
    return r.tap { it.update!(status: "cancelled", detail: reason) }.status if reason

    r.update!(discount_percent: setting.discount_percent, eligible_keys: setting.eligible_keys_for(r.items),
              expires_at: setting.valid_days.days.from_now)
    CartReminderMailer.reminder(r).deliver_now
    r.update!(status: "sent", sent_at: Time.current, detail: nil)
    "sent"
  rescue => e
    Rails.logger.error("cart reminder #{r.id} failed: #{e.class}: #{e.message}")
    r.update_columns(status: "failed", detail: "#{e.class}: #{e.message}".truncate(250), updated_at: Time.current)
    "failed"
  end

  # Called when this browser (or this order) completes a purchase.
  def converted!(sid: nil, order: nil)
    scope = CartReminder.where(status: %w[pending sent])
    ids = []
    ids += scope.where(sid: sid).pluck(:id) if sid
    ids += scope.where(order_id: order.id).or(scope.where(used_order_id: order.id)).pluck(:id) if order
    ids += scope.where("lower(email) = ?", order.customer_email.downcase).where(status: "pending").pluck(:id) if order&.customer_email.present?
    CartReminder.where(id: ids.uniq).update_all(status: "converted", detail: (order && "Order #{order.number}"), updated_at: Time.current)
  end
end
