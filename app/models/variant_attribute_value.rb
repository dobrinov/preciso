class VariantAttributeValue < ApplicationRecord
  belongs_to :variant_attribute
  # Removing a value (or its attribute) cleanly drops it from any variant that
  # used it, rather than hitting the variant_values FK and raising on destroy.
  has_many :variant_values, dependent: :destroy

  default_scope { order(:position) }
  validates :value, presence: true

  def label = "#{variant_attribute.name}: #{value}"
end
