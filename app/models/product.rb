class Product < ApplicationRecord
  belongs_to :category, optional: true
  has_many_attached :images
  has_many :set_items, dependent: :destroy
  has_many :collection_memberships, dependent: :destroy
  has_many :collections, through: :collection_memberships
  has_many :variants, dependent: :destroy

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  def tone = category&.tone || "#f3efe9"
  def kind = "product"

  def has_variants? = variants.exists?

  # Minimum current variant price, for "from €X" display.
  def price_from
    variants.map(&:current_price_via_product).min || current_price
  end

  # The first attachment is treated as the cover image.
  # Falls back to the first variant's cover if the product has no direct images.
  def primary_image
    return images.first if images.attached?

    variants.detect(&:primary_image)&.primary_image
  end

  # Base price, optionally for a specific variant (variant support arrives in a later phase).
  def base_price(variant: nil)
    variant ? variant.price : price
  end

  # Price after any active campaign discount.
  def current_price(variant: nil)
    base = base_price(variant: variant)
    campaign_item ? campaign_item.price_for(base) : base
  end

  def on_sale?(variant: nil)
    current_price(variant: variant) < base_price(variant: variant)
  end

  # Active campaign discount for this product, memoized per instance (caches
  # nil too, so the common "no active campaign" case is a single query).
  def campaign_item
    return @campaign_item if defined?(@campaign_item)
    @campaign_item = Campaign.discount_for("product", id)
  end
end
