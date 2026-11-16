# Sends one Newsletter to every active subscriber, one email each (so every
# message carries its own unsubscribe link). A failed address is counted and
# skipped, never stops the rest.
class NewsletterJob < ApplicationJob
  queue_as :default

  def perform(newsletter_id)
    newsletter = Newsletter.find_by(id: newsletter_id) or return
    sent = failed = 0
    Subscriber.active.find_each do |sub|
      SubscriberMailer.announcement(newsletter, sub).deliver_now
      sent += 1
    rescue => e
      failed += 1
      Rails.logger.error("newsletter #{newsletter.id} to #{sub.id} failed: #{e.class}: #{e.message}")
    ensure
      newsletter.update_columns(sent_count: sent, failed_count: failed, updated_at: Time.current)
    end
    newsletter.update!(status: sent.zero? && failed.positive? ? "failed" : "sent", finished_at: Time.current)
  end
end
