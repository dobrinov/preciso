class About < ApplicationRecord
  # body is stored as a JSON array of paragraph strings.
  serialize :body, coder: JSON, type: Array
  has_one_attached :image

  def self.instance
    first || create!(
      title: "From a small studio, one piece at a time",
      lead: "Preciso is the porcelain studio of Bianna Taynova.",
      body: [],
      signature: "Bianna Taynova",
      studio: "Studio Preciso · by appointment"
    )
  end

  def paragraphs
    Array(body).reject { |p| p.to_s.strip.empty? }
  end
end
