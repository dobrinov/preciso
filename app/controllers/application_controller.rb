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

  # Real client IP. Fly's proxy sets Fly-Client-IP; remote_ip is the local fallback.
  def client_ip
    request.headers["Fly-Client-IP"].presence || request.remote_ip
  end

  # True while signed into the admin — analytics is suppressed so the studio's
  # own browsing doesn't pollute the numbers.
  def admin_signed_in?
    session[:admin].present?
  end

  # Record a storefront pageview. Admin views and signed-in admin browsing are
  # never tracked.
  def track(page_key, label, piece: false, name: nil)
    return if admin_signed_in?
    Event.create!(
      event_type: "pageview", sid: analytics_sid, page_key: page_key,
      label: label, piece: piece, name: name, occurred_at: Time.current,
      ip: client_ip, user_agent: request.user_agent
    )
  rescue => e
    Rails.logger.warn("analytics track failed: #{e.message}")
  end
end
