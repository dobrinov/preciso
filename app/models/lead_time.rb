# Singleton: the studio's wording for how long pieces take — ready to ship
# (in stock) vs. made to order. Shown on product pages, cart, checkout, emails.
class LeadTime < ApplicationRecord
  DEFAULTS = {
    ready_note: "Sent within 2–3 working days",
    made_note: "Ready to send in about 3–4 weeks"
  }.freeze

  def self.instance
    first || create!(DEFAULTS)
  end

  def ready = ready_note.presence || DEFAULTS[:ready_note]
  def made = made_note.presence || DEFAULTS[:made_note]
end
