class Campaign < ApplicationRecord
  has_one_attached :banner
  has_many :campaign_items, dependent: :destroy

  default_scope { order(:id) }
  scope :active, -> { where(active: true) }

  before_validation :assign_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :percent_off, presence: true, numericality: { only_integer: true, in: 1..99 },
            if: :all_products?
  validate :single_active_campaign, if: :active

  def to_param = slug

  # The active discount for a catalogue item, or nil. At most one campaign is
  # active (enforced by validation); an all-products campaign discounts every
  # item by percent_off via a transient (unsaved) CampaignItem.
  def self.discount_for(kind, id)
    campaign = active.first
    return nil unless campaign
    if campaign.all_products?
      CampaignItem.new(discount_kind: "percent", percent_off: campaign.percent_off)
    else
      campaign.campaign_items.find_by(kind: kind.to_s, item_id: id)
    end
  end

  private

  def single_active_campaign
    return unless Campaign.where(active: true).where.not(id: id).exists?
    errors.add(:base, "Another campaign is already active — deactivate it before activating this one.")
  end

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
