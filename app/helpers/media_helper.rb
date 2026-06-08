module MediaHelper
  # The faint vessel silhouette behind every placeholder.
  PORCELAIN_GLYPH = <<~SVG.freeze
    <svg viewBox="0 0 200 200" width="100%" height="100%" class="ph-glyph" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
      <defs>
        <linearGradient id="vg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#fff" stop-opacity="0.9" />
          <stop offset="1" stop-color="#7d766b" stop-opacity="0.5" />
        </linearGradient>
      </defs>
      <ellipse cx="100" cy="150" rx="46" ry="9" fill="#000" opacity="0.06" />
      <path d="M64 92 q-6 30 12 48 q24 16 48 0 q18 -18 12 -48 q-2 -10 -36 -10 q-34 0 -36 10 Z" fill="url(#vg)" />
      <path d="M64 92 q36 14 72 0" fill="none" stroke="#fff" stroke-opacity="0.5" stroke-width="1.5" />
    </svg>
  SVG

  # Labeled placeholder used wherever a photo will eventually go.
  def placeholder(tone: nil, name: nil, caption: nil, ratio: nil)
    bg = tone || "var(--paper-2)"
    style = "background:" \
      "radial-gradient(120% 90% at 30% 18%, rgba(255,255,255,.85), rgba(255,255,255,0) 55%)," \
      "radial-gradient(120% 120% at 78% 96%, rgba(0,0,0,.05), rgba(0,0,0,0) 60%),#{bg};"
    inner = content_tag(:div, class: "ph", style: style) do
      concat PORCELAIN_GLYPH.html_safe
      concat(content_tag(:div, class: "ph-label") do
        concat content_tag(:div, caption, class: "ph-cap") if caption
        concat content_tag(:div, name, class: "ph-name") if name
      end)
    end

    if ratio
      content_tag(:div, inner, class: "ratio-box", style: "padding-top:#{ratio};")
    else
      content_tag(:div, inner, class: "ph-fill")
    end
  end

  # The cover attachment: products keep many images (first is the cover),
  # sets keep a single image.
  def cover_attachment(record)
    if record.respond_to?(:primary_image)
      record.primary_image
    elsif record.respond_to?(:image) && record.image.attached?
      record.image
    end
  end

  # Render a record's attached image, or fall back to the placeholder.
  # kind: "product" | "set"; ratio: e.g. "118%"; cover: fill 1:1 frame.
  def media_for(record, kind:, caption: nil, ratio: nil, cover: false)
    tone = kind == "set" ? Category::TONES["set"] : (record.respond_to?(:tone) ? record.tone : nil)
    cap = caption || (kind == "set" ? "set · photo" : "photo")
    attachment = cover_attachment(record)

    if attachment
      if ratio
        content_tag(:div, class: "ratio-box img-frame", style: "padding-top:#{ratio};") do
          image_tag attachment, alt: record.name, class: "cover-img"
        end
      else
        image_tag attachment, alt: record.name, class: cover ? "cover-img" : "contain-img"
      end
    else
      placeholder(tone: tone, name: record.name, caption: cap, ratio: ratio)
    end
  end
end
