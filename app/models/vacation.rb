class Vacation < ApplicationRecord
  # Singleton: when active, checkout shows a confirmation about slower processing.
  def self.instance
    first || create!(
      active: false,
      message: "Orders placed now may take a little longer than usual to prepare. " \
               "Thank you for your patience — Bianna will be in touch to confirm timing."
    )
  end
end
