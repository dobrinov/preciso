module AnalyticsHelper
  def pct(v)
    v = v.to_f
    return "0%" if v.zero?
    v < 1 ? "#{v.round(2)}%" : (v < 10 ? "#{v.round(1)}%" : "#{v.round}%")
  end

  def share(part, whole) = whole.to_i.positive? ? part.to_f * 100 / whole : 0

  def device_label(device) = { "phone" => "Phone", "tablet" => "Tablet", "desktop" => "Desktop" }[device] || "Unknown device"

  def duration_label(seconds)
    s = seconds.to_i
    return "#{s}s" if s < 60
    return "#{s / 60}m #{format('%02d', s % 60)}s" if s < 3600
    "#{s / 3600}h #{(s % 3600) / 60}m"
  end

  def visit_day(ts)
    return "Today" if ts.to_date == Date.current
    return "Yesterday" if ts.to_date == Date.yesterday
    ts.strftime(ts.year == Date.current.year ? "%b %-d" : "%b %-d, %Y")
  end

  def timeline_kind(e)
    case e.event_type
    when "pageview" then "page"
    when "add_cart", "remove_cart" then "cart"
    when "order" then "order"
    else "step"
    end
  end

  def timeline_text(e, first)
    case e.event_type
    when "pageview" then first ? "Landed on #{e.label}" : e.label
    when "add_cart" then "Added to cart · #{e.label}#{" ×#{e.qty}" if e.qty.to_i > 1}"
    when "remove_cart" then "Removed from cart · #{e.label}#{" ×#{e.qty}" if e.qty.to_i > 1}"
    when "checkout_submit" then "Sent checkout form · #{e.label}#{" · #{e.name}" if e.name.present?}"
    when "payment_start" then "Went to card payment · #{e.label}"
    when "payment_cancel" then "Cancelled payment · #{e.label}"
    when "order" then "Order #{e.label} placed · #{money(e.total)}"
    when "reminder_open" then "Came back from the cart reminder email · #{e.label}"
    else e.event_type.humanize
    end
  end

  # Readable "Browser · OS" from a raw user-agent. Order matters: Edge/Opera embed
  # "Chrome", and Chrome embeds "Safari", so check the more specific ones first.
  def browser_label(ua)
    return "Unknown" if ua.blank?
    browser = case ua
    when /Instagram/ then "Instagram app"
    when /FBAN|FBAV/ then "Facebook app"
    when /Edg/ then "Edge"
    when /OPR|Opera/ then "Opera"
    when /Chrome|CriOS/ then "Chrome"
    when /Firefox|FxiOS/ then "Firefox"
    when /Safari/ then "Safari"
    else "Other"
    end
    os = case ua
    when /iPhone|iPad|iPod|iOS/ then "iOS"
    when /Android/ then "Android"
    when /Mac OS X|Macintosh/ then "macOS"
    when /Windows/ then "Windows"
    when /Linux/ then "Linux"
    end
    os ? "#{browser} · #{os}" : browser
  end
end
