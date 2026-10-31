# A fixed delivery price (whole €) for one country. Countries without a rate
# fall back to the original flow: order placed without online payment, and the
# studio quotes delivery by hand.
class DeliveryRate < ApplicationRecord
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

  validates :country_code, inclusion: { in: COUNTRIES.keys }, uniqueness: true
  validates :cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.sorted = all.sort_by(&:name)

  def name = COUNTRIES[country_code]
end
