# Helpers for the order emails (app/views/order_mailer). Email HTML is
# table-based with inline styles so it renders in Gmail, Outlook and Apple Mail;
# the web fonts load where supported, with Georgia / Helvetica as fallbacks.
module EmailHelper
  SERIF = "'Cormorant Garamond', Georgia, 'Times New Roman', serif".freeze
  SANS  = "Jost, 'Helvetica Neue', Helvetica, Arial, sans-serif".freeze
  MONO  = "'JetBrains Mono', Menlo, Consolas, monospace".freeze

  INK = "#1c1a17".freeze
  INK_SOFT = "#3a3631".freeze
  MUTED = "#6f6961".freeze # darker than the site's --muted so small text stays readable
  LINE = "#e8e4de".freeze
  PAPER = "#faf8f5".freeze
  ACCENT = "#7e664b".freeze # --clay-deep

  def first_name(order) = order.customer_name.to_s.split(" ").first

  def order_number_tag(order)
    tag.span(order.number, style: "font-family:#{MONO};font-size:13px;color:#{ACCENT};")
  end

  # Absolute URL of the line's photo (variant photo first, then the piece's
  # cover), or nil when there is none — the template draws a tone swatch.
  def line_image_url(line)
    variant = Variant.find_by(id: line.variant_id) if line.variant_id
    attachment = variant&.primary_image || (line.record && cover_attachment(line.record))
    rails_blob_url(attachment) if attachment
  rescue StandardError
    nil
  end

  # Cover image for a cart line (Cart::Line: live record + variant).
  def reminder_image_url(line)
    attachment = line.variant&.primary_image || cover_attachment(line.record)
    rails_blob_url(attachment) if attachment
  rescue StandardError
    nil
  end

  # Admin-written text: escaped, line breaks kept.
  def simple_format_inline(text) = safe_join(text.to_s.split("\n"), tag.br)

  def line_tone(line)
    line.record.respond_to?(:tone) && line.record.tone.presence || "#f3efe9"
  end

  # "Ana Petrova<br>ul. Vitosha 1<br>1000 Sofia<br>Bulgaria", escaped.
  def address_html(order)
    safe_join([ order.customer_name, *order.delivery_lines ].compact_blank, tag.br)
  end

  def contact_html(order)
    safe_join([ order.customer_email, order.customer_phone ].compact_blank, tag.br)
  end

  # "Visa ending 4111 · via myPOS" from the stored payment details.
  def paid_with(order)
    return "Paid online via myPOS" if order.payment_details.blank?
    parts = order.payment_details.split(" · ")
    pan = parts.find { |p| p.match?(/\A\d{4}\z/) }
    brand = parts.find { |p| p.match?(/[A-Za-z]/) } || "Card"
    [ pan ? "#{brand} ending #{pan}" : brand, "via myPOS" ].join(" · ")
  end

  # "On its way" email body, by delivery type.
  def fulfilled_body(order)
    if order.office_delivery?
      "Your order has left the studio and is on its way #{order.delivery_phrase}#{" (#{order.delivery_office})" if order.delivery_office.present?}. " \
        "The courier will let you know when it's ready to collect. We hope you enjoy every piece."
    elsif order.delivery_destination?
      "Your order has left the studio and is on its way #{order.delivery_phrase}. We hope you enjoy every piece."
    else
      "Your order is complete and has left the studio. We hope you enjoy every piece."
    end
  end

  def label_style(extra = "")
    "font-family:#{SANS};font-size:11px;letter-spacing:2.4px;text-transform:uppercase;color:#{MUTED};#{extra}"
  end
end
