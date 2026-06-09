class Variant < ApplicationRecord
  include ImageOrdering

  belongs_to :product
  has_many_attached :images
  has_many :variant_values, dependent: :destroy
  has_many :variant_attribute_values, through: :variant_values

  default_scope { order(:position) }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  # Custom name when set, otherwise the attribute combination.
  def label
    name.presence || options_label
  end

  # "Large / Red", ordered by attribute position.
  def options_label
    variant_attribute_values
      .includes(:variant_attribute)
      .sort_by { |v| v.variant_attribute.position }
      .map(&:value).join(" / ")
  end

  def primary_image
    ordered_images.first if images.attached?
  end

  def current_price_via_product
    product.current_price(variant: self)
  end
end
