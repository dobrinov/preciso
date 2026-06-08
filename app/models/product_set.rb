class ProductSet < ApplicationRecord
  has_one_attached :image
  has_many :set_items, -> { order(:position) }, dependent: :destroy
  has_many :products, through: :set_items

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  def tone = Category::TONES["set"]
  def kind = "set"

  # Flatten set_items into a grouped list of { product:, qty: } preserving order.
  def grouped_items
    set_items.includes(product: { images_attachments: :blob }).map do |si|
      { product: si.product, qty: si.quantity } if si.product
    end.compact
  end

  def piece_count
    set_items.sum(:quantity)
  end

  # Total if every piece were bought separately.
  def separate_total
    set_items.includes(:product).sum { |si| (si.product&.price || 0) * si.quantity }
  end

  def base_price(variant: nil)
    price
  end

  def current_price(variant: nil)
    base = base_price(variant: variant)
    campaign_item ? campaign_item.price_for(base) : base
  end

  def on_sale?(variant: nil)
    current_price(variant: variant) < base_price(variant: variant)
  end

  # Active campaign discount for this set, memoized per instance (caches nil too).
  def campaign_item
    return @campaign_item if defined?(@campaign_item)
    @campaign_item = Campaign.discount_for("set", id)
  end
end
