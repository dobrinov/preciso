module ApplicationHelper
  CURRENCY = "€".freeze

  def money(n)
    "#{CURRENCY}#{n.to_i}"
  end

  # "2 days ago" style relative time.
  def time_ago(ts)
    return "" unless ts
    s = (Time.current - ts).to_i
    return "just now" if s < 60
    m = s / 60
    return "#{m} min ago" if m < 60
    h = m / 60
    return "#{h} #{'hour'.pluralize(h)} ago" if h < 24
    d = h / 24
    "#{d} #{'day'.pluralize(d)} ago"
  end

  def date_label(ts)
    ts&.strftime("%d %b %Y")
  end

  def link_path_for(line_or_record, kind)
    kind == "set" ? product_set_path(line_or_record) : product_path(line_or_record)
  end

  # Renders the current price, with the original struck through when discounted.
  def price_tag(record, variant: nil)
    cur = record.current_price(variant: variant)
    base = record.base_price(variant: variant)
    if cur < base
      safe_join([
        content_tag(:span, money(cur), class: "price-now"),
        content_tag(:span, money(base), class: "price-was")
      ], " ")
    else
      money(cur)
    end
  end
end
