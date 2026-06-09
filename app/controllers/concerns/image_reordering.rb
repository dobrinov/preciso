# Admin image handling for has_many_attached :images records: purge marked images,
# attach newly uploaded files, then persist the drag-and-drop display order.
#
# The form submits image_order_tokens[] in tile order — each existing tile its
# attachment id, each new-upload tile the literal "new". New tokens map to the
# just-attached attachments in upload order; the result is saved to image_order.
module ImageReordering
  extend ActiveSupport::Concern

  private

  def apply_images(record, files:, remove_ids:, tokens:)
    purge_marked_images(record, remove_ids)

    new_files = Array(files).reject(&:blank?)
    before = record.images.attachments.pluck(:id)
    record.images.attach(new_files) if new_files.any?
    just_attached = record.images.attachments.pluck(:id) - before

    store_image_order(record, Array(tokens), just_attached)
  end

  def purge_marked_images(record, remove_ids)
    ids = Array(remove_ids).reject(&:blank?)
    record.images.attachments.where(id: ids).find_each(&:purge) if ids.any?
  end

  # Resolve the submitted tile order into an array of attachment ids.
  def store_image_order(record, tokens, just_attached)
    attached_ids = record.images.attachments.pluck(:id)
    queue = just_attached.dup
    ordered = tokens.filter_map do |tok|
      if tok == "new"
        queue.shift
      else
        id = tok.to_i
        id if attached_ids.include?(id)
      end
    end
    ordered.concat(attached_ids - ordered) # safety net for anything not in the tokens
    record.update!(image_order: ordered)
  end
end
