# A way of delivering to one country, with a fixed price (whole €):
# e.g. Bulgaria — "Econt office" (office, €4). A country can have several;
# the customer picks one at checkout. Countries without options fall back to
# the original flow: order placed without online payment, delivery quoted by
# hand.
class DeliveryOption < ApplicationRecord
  KINDS = {
    "address" => "To an address",
    "office"  => "To a courier office"
  }.freeze

  COUNTRIES = {
    "AL" => "Albania", "AD" => "Andorra", "AT" => "Austria", "BY" => "Belarus", "BE" => "Belgium",
    "BA" => "Bosnia and Herzegovina", "BG" => "Bulgaria", "HR" => "Croatia", "CY" => "Cyprus",
    "CZ" => "Czechia", "DK" => "Denmark", "EE" => "Estonia", "FI" => "Finland", "FR" => "France",
    "DE" => "Germany", "GR" => "Greece", "HU" => "Hungary", "IS" => "Iceland", "IE" => "Ireland",
    "IT" => "Italy", "XK" => "Kosovo", "LV" => "Latvia", "LI" => "Liechtenstein", "LT" => "Lithuania",
    "LU" => "Luxembourg", "MT" => "Malta", "MD" => "Moldova", "MC" => "Monaco", "ME" => "Montenegro",
    "NL" => "Netherlands", "MK" => "North Macedonia", "NO" => "Norway", "PL" => "Poland",
    "PT" => "Portugal", "RO" => "Romania", "SM" => "San Marino", "RS" => "Serbia", "SK" => "Slovakia",
    "SI" => "Slovenia", "ES" => "Spain", "SE" => "Sweden", "CH" => "Switzerland", "TR" => "Türkiye",
    "UA" => "Ukraine", "GB" => "United Kingdom",
    "AU" => "Australia", "BR" => "Brazil", "CA" => "Canada", "CN" => "China", "IL" => "Israel",
    "JP" => "Japan", "MX" => "Mexico", "NZ" => "New Zealand", "SG" => "Singapore",
    "ZA" => "South Africa", "KR" => "South Korea", "AE" => "United Arab Emirates", "US" => "United States"
  }.sort_by { |_, name| name }.to_h.freeze

  validates :country_code, inclusion: { in: COUNTRIES.keys }
  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS.keys }
  validates :cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # { "BG" => [options…], … } ordered by country name, then position.
  def self.by_country
    all.sort_by { |o| [ o.country_name, o.position, o.id ] }.group_by(&:country_code)
  end

  def country_name = COUNTRIES[country_code]
  def office? = kind == "office"
end
