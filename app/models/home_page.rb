class HomePage < ApplicationRecord
  # Singleton: the editable text of the home page (hero + maker) and the
  # site-wide footer blurb. Seeded with the current copy on first access.
  def self.instance
    first || create!(
      hero_eyebrow: "Handmade Porcelain · Bianna Taynova",
      hero_title: "Quiet objects\nfor daily",
      hero_accent: "rituals",
      hero_subtext: "Hand-built bowls, cups and vases in fine white porcelain — finished by hand, made in small batches, sold as they leave the kiln.",
      maker_eyebrow: "The maker",
      maker_title: "Made by one pair of hands",
      maker_text: "Each piece begins as fine porcelain and is built entirely by hand — shaped, refined, glazed and fired. Small differences are the record of how it was made.",
      footer_blurb: "Handmade porcelain by Bianna Taynova. Shaped, trimmed and glazed by hand in small batches."
    )
  end
end
