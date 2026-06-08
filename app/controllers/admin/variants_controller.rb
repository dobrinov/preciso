module Admin
  class VariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: [ :edit, :update, :destroy ]

    def new
      @variant = @product.variants.new
    end

    def create
      @variant = @product.variants.new(price: params.dig(:variant, :price).to_i)
      if @variant.save
        rebuild_values(@variant)
        attach_images(@variant)
        redirect_to edit_admin_product_path(@product)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @variant.update(price: params.dig(:variant, :price).to_i)
        rebuild_values(@variant)
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

    def rebuild_values(variant)
      ids = Array(params[:value_ids]).reject(&:blank?).uniq
      variant.variant_values.destroy_all
      ids.each { |vid| variant.variant_values.create!(variant_attribute_value_id: vid) if VariantAttributeValue.exists?(vid) }
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
