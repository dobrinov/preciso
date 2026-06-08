module IconsHelper
  # Stroke icons (1.4) ported from the prototype's `Ic` set.
  ICONS = {
    cart:  %(<path d="M3 5h2l2.2 11.2a1 1 0 0 0 1 .8h8.6a1 1 0 0 0 1-.8L20.5 8H6"/><circle cx="9.5" cy="20" r="1.1"/><circle cx="17.5" cy="20" r="1.1"/>),
    close: %(<path d="M6 6l12 12M18 6L6 18"/>),
    arrow: %(<path d="M5 12h14M13 6l6 6-6 6"/>),
    back:  %(<path d="M19 12H5M11 6l-6 6 6 6"/>),
    plus:  %(<path d="M12 5v14M5 12h14"/>),
    minus: %(<path d="M5 12h14"/>),
    trash: %(<path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/>),
    edit:  %(<path d="M4 20h4L19 9l-4-4L4 16v4ZM14 6l4 4"/>),
    menu:  %(<path d="M3 6h18M3 12h18M3 18h18"/>),
    check: %(<path d="M5 13l4 4L19 7"/>),
    grid:  %(<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/>),
    box:   %(<path d="M3 7l9-4 9 4-9 4-9-4ZM3 7v10l9 4 9-4V7M12 11v10"/>),
    layers: %(<path d="M12 3l9 5-9 5-9-5 9-5ZM3 13l9 5 9-5"/>),
    bag:   %(<path d="M6 8h12l-1 12H7L6 8ZM9 8V6a3 3 0 0 1 6 0v2"/>),
    doc:   %(<path d="M6 3h8l4 4v14H6V3ZM14 3v4h4M9 12h6M9 16h6"/>),
    out:   %(<path d="M14 4h5v16h-5M11 8l-4 4 4 4M7 12h9"/>),
    store: %(<path d="M4 9l1-5h14l1 5M4 9v11h16V9M4 9h16M9 20v-6h6v6"/>),
    user:  %(<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/>),
    chart: %(<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>),
    tag:   %(<path d="M3 11l8-8 10 10-8 8-10-10ZM3 11V4h7"/><circle cx="8.5" cy="8.5" r="1.2"/>),
    instagram: %(<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.2" cy="6.8" r="1"/>),
    facebook:  %(<path d="M14 8h2V5h-2a3 3 0 0 0-3 3v2H9v3h2v6h3v-6h2.2l.4-3H14v-1.6c0-.5.2-.4.6-.4Z"/>)
  }.freeze

  def icon(name, size: 18, **opts)
    body = ICONS[name.to_sym] or return "".html_safe
    attrs = {
      viewBox: "0 0 24 24", width: size, height: size, fill: "none",
      stroke: "currentColor", "stroke-width": 1.4
    }.merge(opts)
    tag.svg(body.html_safe, **attrs)
  end
end
