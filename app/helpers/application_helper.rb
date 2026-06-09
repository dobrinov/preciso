module ApplicationHelper
  CURRENCY = "€".freeze

  def money(n)
    "#{CURRENCY}#{n.to_i}"
  end

  # The editable home-page / footer text singleton, memoized per request so the
  # home view and the site-wide footer share one query.
  def home_page
    @_home_page ||= HomePage.instance
  end

  # Make an asset/blob path absolute for og:image (scrapers need a full URL).
  def absolute_url(path)
    path.to_s.start_with?("http") ? path : "#{request.base_url}#{path}"
  end

  # Whether an image source has an attached blob. Handles a has_one_attached
  # proxy (responds to attached?), a single ActiveStorage::Attachment (e.g.
  # Product#primary_image), or nil.
  def og_image?(image)
    return false if image.nil?
    image.respond_to?(:attached?) ? image.attached? : image.present?
  end

  # Absolute URL for a record's image, falling back to the brand share image.
  def og_image_url(image)
    absolute_url(og_image?(image) ? url_for(image) : image_path("og-image.png"))
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
