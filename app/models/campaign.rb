class Campaign < ApplicationRecord
  has_one_attached :banner
  has_many :campaign_items, dependent: :destroy

  default_scope { order(:id) }
  scope :active, -> { where(active: true) }

  before_validation :assign_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def to_param = slug

  # The active discount for a catalogue item, or nil. First active campaign wins.
  def self.discount_for(kind, id)
    CampaignItem.joins(:campaign)
                .where(campaigns: { active: true }, kind: kind.to_s, item_id: id)
                .order("campaigns.id")
                .first
  end

  private

  def assign_slug
    if new_record?
      self.slug = generate_slug if slug.blank?
    elsif name_changed?
      self.slug = generate_slug
    end
  end

  def generate_slug
    base = name.to_s.parameterize.presence || "campaign"
    candidate = base
    i = 2
    while Campaign.unscoped.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{i}"
      i += 1
    end
    candidate
  end
end
