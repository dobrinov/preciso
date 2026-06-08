class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_cart

  def current_cart
    @current_cart ||= Cart.new(session)
  end

  private

  # One id per browser session, mirroring the prototype's on-device counting.
  def analytics_sid
    session[:sid] ||= "s-#{SecureRandom.hex(4)}"
  end

  # Record a storefront pageview (admin views are never tracked).
  def track(page_key, label, piece: false, name: nil)
    Event.create!(
      event_type: "pageview", sid: analytics_sid, page_key: page_key,
      label: label, piece: piece, name: name, occurred_at: Time.current
    )
  rescue => e
    Rails.logger.warn("analytics track failed: #{e.message}")
  end
end
