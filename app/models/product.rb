class Product < ApplicationRecord
  belongs_to :category, optional: true
  has_many_attached :images
  has_many :set_items, dependent: :destroy
  has_many :collection_memberships, dependent: :destroy
  has_many :collections, through: :collection_memberships

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  def tone = category&.tone || "#f3efe9"
  def kind = "product"

  # The first attachment is treated as the cover image.
  def primary_image
    images.first if images.attached?
  end

  # Base price, optionally for a specific variant (variant support arrives in a later phase).
  def base_price(variant: nil)
    variant ? variant.price : price
  end

  # Price after any active campaign discount.
  def current_price(variant: nil)
    base = base_price(variant: variant)
    ci = Campaign.discount_for("product", id)
    ci ? ci.price_for(base) : base
  end

  def on_sale?(variant: nil)
    current_price(variant: variant) < base_price(variant: variant)
  end
end
