class SetItem < ApplicationRecord
  belongs_to :product_set
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
end
