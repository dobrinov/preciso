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
end
