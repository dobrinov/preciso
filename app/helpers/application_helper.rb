module ApplicationHelper
  CURRENCY = "€".freeze
  # Single canonical domain so apex / www / fly.dev aren't treated as duplicates.
  CANONICAL_HOST = "https://www.precisodesign.com".freeze

  def money(n)
    "#{CURRENCY}#{n.to_i}"
  end

  # Short delivery line for product pages and the cart, e.g.
  # "Delivery across Bulgaria from €4 · pay by card". Reflects the delivery
  # options and whether card payments are on.
  def delivery_note
    @_delivery_note ||= build_delivery_note
  end

  def build_delivery_note
    from = DeliveryOption.minimum(:cost)
    countries = DeliveryOption.distinct.count(:country_code)
    where = countries == 1 ? "across #{DeliveryOption.first.country_name}" : "to #{countries} countries"
    return "Delivery & payment arranged after you order" unless from
    "Delivery #{where} from #{money from} · #{Mypos.enabled? ? "pay by card" : "payment arranged after you order"}"
  end

  # Canonical absolute URL for a path (defaults to the current request path).
  def canonical_url(path = nil)
    "#{CANONICAL_HOST}#{path || request.path}"
  end

  # The editable home-page / footer text singleton, memoized per request so the
  # home view and the site-wide footer share one query.
  def home_page
    @_home_page ||= HomePage.instance
  end

  # Ready-to-ship vs made-to-order wording (memoized per request).
  def lead_time
    @_lead_time ||= LeadTime.instance
  end

  # "Buy" when the studio has it ready to ship, "Request" when it's made to order.
  def order_verb(ready) = ready ? "Buy" : "Request"

  # Availability line for product/set pages: a label plus the lead time.
  # The studio's actual stock count is never shown.
  def availability_tag(ready, **opts)
    content_tag(:div, class: "availability #{ready ? "is-ready" : "is-made"}", **opts) do
      safe_join([
        content_tag(:span, "", class: "availability-dot"),
        content_tag(:span, ready ? "Ready to ship" : "Made to order", class: "availability-label"),
        content_tag(:span, ready ? lead_time.ready : lead_time.made, class: "availability-note")
      ])
    end
  end

  # One sentence on when an order will be sent, for the confirmation page and
  # customer emails.
  def order_timing(order)
    lc = ->(s) { s.sub(/\A\p{Lu}/) { |c| c.downcase } }
    if order.all_from_stock?
      "Everything in your order is ready to ship — #{lc[lead_time.ready]}."
    elsif order.order_lines.none?(&:from_stock)
      "Your pieces are made to order — #{lc[lead_time.made]}."
    else
      "Some of your pieces are made to order — #{lc[lead_time.made]}. We'll send everything together once it's ready."
    end
  end

  # Admin-only stock summary: "3 in stock" / "Made to order". A piece with
  # variations adds up its variations' stock.
  def stock_label(record)
    count = record.is_a?(Product) && record.has_variants? ? record.variants.sum { |v| v.stock.to_i } : record.stock.to_i
    count.positive? ? "#{count} in stock" : "Made to order"
  end

  # Short per-line tag for cart, checkout and the order confirmation.
  def line_ready_tag(ready)
    content_tag(:span, ready ? "Ready to ship" : "Made to order", class: "line-ready #{ready ? "is-ready" : "is-made"}")
  end

  # The vacation/slower-processing singleton (memoized per request).
  def vacation
    @_vacation ||= Vacation.instance
  end

  # The seller's legal details + policy texts (memoized per request).
  def legal_info
    @_legal_info ||= LegalInfo.instance
  end

  # Make an asset/blob path absolute against the canonical host (og:image, JSON-LD).
  def absolute_url(path)
    path.to_s.start_with?("http") ? path : "#{CANONICAL_HOST}#{path}"
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

  # BreadcrumbList JSON-LD mirroring the visible breadcrumb (Home + the trail).
  # trail is an array of [name, path]; a nil path (current page) uses the canonical
  # URL. Google requires an item URL on every entry.
  def breadcrumb_jsonld(trail)
    items = ([ [ "Home", root_path ] ] + trail).each_with_index.map do |(name, path), i|
      { "@type" => "ListItem", "position" => i + 1, "name" => name,
        "item" => path ? absolute_url(path) : canonical_url }
    end
    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end

  # schema.org JSON-LD blocks for the current page: Organization site-wide, plus
  # Product on product/set pages (built from the @meta_* values set for OG).
  def structured_data
    blocks = [ {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => "Preciso",
      "url" => CANONICAL_HOST,
      "logo" => absolute_url(image_path("og-image.png"))
    } ]
    if @meta_type == "product"
      blocks << {
        "@context" => "https://schema.org",
        "@type" => "Product",
        "name" => @meta_title,
        "image" => og_image_url(@meta_image),
        "description" => @meta_description,
        "offers" => {
          "@type" => "Offer",
          "price" => @meta_price.to_s,
          "priceCurrency" => "EUR",
          "availability" => "https://schema.org/#{@meta_ready ? "InStock" : "MadeToOrder"}",
          "url" => canonical_url
        }
      }
    end
    blocks
  end
end
