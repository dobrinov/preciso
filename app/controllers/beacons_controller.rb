# The page-load beacon (pv_controller.js). Proves a real browser rendered and
# ran the page, and reports how long the page stayed open. The token is a
# signed event id, so no CSRF token is needed and ids can't be forged.
class BeaconsController < ApplicationController
  skip_forgery_protection

  def create
    id = Rails.application.message_verifier(:pv).verified(params[:t].to_s)
    event = id && Event.find_by(id: id, event_type: "pageview")
    if event
      changes = {}
      changes[:verified_at] = Time.current if event.verified_at.nil?
      d = params[:d].to_i
      changes[:duration_ms] = [ d, 6.hours.in_milliseconds ].min if d.positive? && event.duration_ms.nil?
      event.update_columns(changes) if changes.any?
    end
    head :no_content
  rescue => e
    Rails.logger.warn("analytics beacon failed: #{e.message}")
    head :no_content
  end
end
