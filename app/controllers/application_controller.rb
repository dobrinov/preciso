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

  # Analytics "order" event — once per order, never for admin browsing.
  def record_order_event(order)
    return if Event.exists?(event_type: "order", label: order.number)
    record_event("order", label: order.number, total: order.total)
  end

  # Record a storefront pageview. Admin views and signed-in admin browsing are
  # never tracked. The page carries a signed token so the beacon script can
  # confirm a real browser rendered it (see pv_controller.js).
  def track(page_key, label, piece: false, name: nil)
    referrer = request.referer.to_s.first(500).presence
    event = record_event("pageview", page_key:, label:, piece:, name:,
      referrer: (referrer unless internal_referrer?(referrer)),
      source: Event.source_for(referrer:, utm_source: params[:utm_source], user_agent: request.user_agent, own_host: request.host),
      campaign: params[:utm_campaign].to_s.first(100).presence)
    @pv_token = Rails.application.message_verifier(:pv).generate(event.id, expires_in: 2.days) if event && !event.bot
  end

  # Shared writer for every analytics event. Failures are logged, never raised:
  # analytics must not break the shop.
  def record_event(type, **attrs)
    return if admin_signed_in?
    ua = request.user_agent.to_s.first(500)
    Event.create!(event_type: type, sid: analytics_sid, occurred_at: Time.current,
                  ip: client_ip, user_agent: ua, bot: Event.bot_agent?(ua), device: Event.device_for(ua), **attrs)
  rescue => e
    Rails.logger.warn("analytics #{type} failed: #{e.message}")
    nil
  end

  def internal_referrer?(ref)
    ref.present? && (URI.parse(ref).host == request.host rescue false)
  end
end
