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
      safe_join([tag.strong("Order placed", style: "font-weight:400"), " — #{e.label} · #{money(e.total)}"])
    when "add_cart"
      safe_join([tag.strong("Added to cart", style: "font-weight:400"), " — #{e.label}"])
    else
      safe_join(["Viewed ", tag.strong(e.label, style: "font-weight:400")])
    end
  end
end
