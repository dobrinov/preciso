class Collection < ApplicationRecord
  has_one_attached :cover
  has_many :collection_memberships, -> { order(:position) }, dependent: :destroy
  has_many :products, through: :collection_memberships

  default_scope { order(:position) }
  scope :nonempty, -> { joins(:collection_memberships).distinct }

  before_validation :assign_slug
  before_create :assign_position

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def to_param = slug

  private

  def assign_slug
    if new_record?
      self.slug = generate_slug if slug.blank?
    elsif name_changed?
      self.slug = generate_slug
    end
  end

  def generate_slug
    base = name.to_s.parameterize.presence || "collection"
    candidate = base
    i = 2
    while Collection.unscoped.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{i}"
      i += 1
    end
    candidate
  end

  def assign_position
    self.position = (Collection.unscoped.maximum(:position) || -1) + 1
  end
end
