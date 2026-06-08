class VariantValue < ApplicationRecord
  belongs_to :variant
  belongs_to :variant_attribute_value
end
