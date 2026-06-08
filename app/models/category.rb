class Category < ApplicationRecord
  has_many :products, dependent: :nullify
  has_one_attached :image

  default_scope { order(:position) }

  before_validation :assign_slug
  before_create :assign_position

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  DEFAULT_TONE = "#ece6dd".freeze

  # Soft per-category tones for placeholder imagery (quiet, near-white).
  # Kept for the "set" tone and as creation defaults.
  TONES = {
    "bowls" => "#efe9e1",
    "cups" => "#ece6de",
    "espresso" => "#e9e2d8",
    "vases" => "#f0ebe4",
    "plates" => "#ece8e1",
    "set" => "#e7e0d6"
  }.freeze

  def tone
    self[:tone].presence || TONES[slug] || DEFAULT_TONE
  end

  private

  # Slugs track the name (so URLs stay meaningful) but only change when the
  # name changes — an explicit slug on create is respected, and existing links
  # to an unrenamed category stay stable.
  def assign_slug
    if new_record?
      self.slug = generate_slug if slug.blank?
    elsif name_changed?
      self.slug = generate_slug
    end
  end

  def generate_slug
    base = name.to_s.parameterize.presence || "category"
    candidate = base
    i = 2
    while Category.unscoped.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{i}"
      i += 1
    end
    candidate
  end

  def assign_position
    self.position = (Category.unscoped.maximum(:position) || -1) + 1
  end
end
