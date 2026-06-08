class VariantAttribute < ApplicationRecord
  has_many :variant_attribute_values, -> { order(:position) }, dependent: :destroy

  default_scope { order(:position) }
  validates :name, presence: true

  accepts_nested_attributes_for :variant_attribute_values
end
