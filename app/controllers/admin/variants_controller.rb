module Admin
  class VariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: [ :edit, :update, :destroy ]

    def new
      @variant = @product.variants.new
    end

    def create
      @variant = @product.variants.new(price: variant_price)
      return render_duplicate(:new) if duplicate_variation?
      if @variant.save
        apply_values(@variant)
        attach_images(@variant)
        redirect_to edit_admin_product_path(@product)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      return render_duplicate(:edit) if duplicate_variation?(except: @variant)
      if @variant.update(price: variant_price)
        apply_values(@variant)
        purge_images(@variant)
        attach_images(@variant)
        redirect_to edit_admin_product_path(@product)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @variant.destroy
      redirect_to edit_admin_product_path(@product)
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_variant
      @variant = @product.variants.find(params[:id])
    end

    def variant_price
      params.dig(:variant, :price).to_i
    end

    # The form posts one value per attribute as value_ids[<attribute_id>] (radio),
    # so a variation can hold at most one value from each attribute. Collect the
    # chosen, non-blank, existing value ids.
    def chosen_value_ids
      @chosen_value_ids ||= params.fetch(:value_ids, {}).values
                                  .reject(&:blank?).map(&:to_i).uniq
                                  .select { |id| VariantAttributeValue.exists?(id) }
    end

    # A variation is a duplicate when another variation of the same product has
    # the identical set of attribute values.
    def duplicate_variation?(except: nil)
      target = chosen_value_ids.sort
      @product.variants.includes(:variant_values).any? do |v|
        next false if except && v.id == except.id

        v.variant_attribute_value_ids.sort == target
      end
    end

    def render_duplicate(action)
      @variant.errors.add(:base, "A variation with these exact options already exists.")
      render action, status: :unprocessable_entity
    end

    def apply_values(variant)
      variant.variant_values.destroy_all
      chosen_value_ids.each { |vid| variant.variant_values.create!(variant_attribute_value_id: vid) }
    end

    def attach_images(variant)
      files = Array(params.dig(:variant, :images)).reject(&:blank?)
      variant.images.attach(files) if files.any?
    end

    def purge_images(variant)
      ids = Array(params[:remove_image_ids]).reject(&:blank?)
      variant.images.attachments.where(id: ids).find_each(&:purge) if ids.any?
    end
  end
end
