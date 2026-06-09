# Explicit display order for a has_many_attached :images collection. The order is
# a JSON array of attachment ids stored in `image_order`; attachments not listed
# (e.g. freshly uploaded) sort last by id, so the result is always stable. Nothing
# is reattached or purged to reorder — only the stored order changes.
module ImageOrdering
  extend ActiveSupport::Concern

  included do
    serialize :image_order, type: Array, coder: JSON
  end

  def ordered_images
    return [] unless images.attached?
    ord = Array(image_order)
    images.attachments.sort_by { |a| [ ord.index(a.id) || Float::INFINITY, a.id ] }
  end
end
