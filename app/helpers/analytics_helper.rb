module AnalyticsHelper
  def chart_day_label(ts, days)
    return ts.day.to_s if days > 14
    "#{ts.strftime('%a')[0, 2]} #{ts.day}"
  end

  def event_icon(type)
    case type
    when "order" then icon(:bag, size: 16)
    when "add_cart" then icon(:cart, size: 16)
    else tag.span(style: "width:6px;height:6px;border-radius:6px;background:var(--line-2);display:inline-block")
    end
  end

  def event_color(type)
    case type
    when "order" then "var(--clay-deep)"
    when "add_cart" then "var(--ink-soft)"
    else "var(--faint)"
    end
  end

  def event_text(e)
    case e.event_type
    when "order"
      safe_join([ tag.strong("Order placed", style: "font-weight:400"), " — #{e.label} · #{money(e.total)}" ])
    when "add_cart"
      safe_join([ tag.strong("Added to cart", style: "font-weight:400"), " — #{e.label}" ])
    else
      safe_join([ "Viewed ", tag.strong(e.label, style: "font-weight:400") ])
    end
  end

  # Readable "Browser · OS" from a raw user-agent. Order matters: Edge/Opera embed
  # "Chrome", and Chrome embeds "Safari", so check the more specific ones first.
  def browser_label(ua)
    return "Unknown" if ua.blank?
    browser = case ua
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

  # The event's IP as a link to a geolocation lookup, plus the browser label.
  def event_origin(e)
    return if e.ip.blank? && e.user_agent.blank?
    parts = []
    parts << link_to(e.ip, "https://tools.keycdn.com/geo?host=#{e.ip}", target: "_blank", rel: "noopener") if e.ip.present?
    parts << browser_label(e.user_agent) if e.user_agent.present?
    safe_join(parts, " · ")
  end
end
