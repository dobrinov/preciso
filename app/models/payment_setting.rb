class PaymentSetting < ApplicationRecord
  # Singleton: the studio's switch for online card payments (myPOS). When off,
  # checkout falls back to the original flow — order placed, studio arranges
  # payment by hand.
  def self.instance
    first || create!(card_payments: false)
  end
end
