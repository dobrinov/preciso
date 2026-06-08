class VariantAttributeValue < ApplicationRecord
  belongs_to :variant_attribute

  default_scope { order(:position) }
  validates :value, presence: true

  def label = "#{variant_attribute.name}: #{value}"
end
