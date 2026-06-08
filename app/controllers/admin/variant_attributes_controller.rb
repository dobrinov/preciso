module Admin
  class VariantAttributesController < BaseController
    before_action :set_attribute, only: [ :edit, :update, :destroy ]

    def index
      @attributes = VariantAttribute.includes(:variant_attribute_values).all
    end

    def new
      @attribute = VariantAttribute.new
    end

    def create
      @attribute = VariantAttribute.new(name: params.dig(:variant_attribute, :name))
      if @attribute.save
        rebuild_values(@attribute)
        redirect_to admin_variant_attributes_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @attribute.update(name: params.dig(:variant_attribute, :name))
        rebuild_values(@attribute)
        redirect_to admin_variant_attributes_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @attribute.destroy
      redirect_to admin_variant_attributes_path
    end

    private

    def set_attribute
      @attribute = VariantAttribute.find(params[:id])
    end

    # Reconcile values by their text (not by row position): existing rows whose
    # value is still submitted keep their id (so future variant references to
    # them survive add/reorder edits); removed values are destroyed; new values
    # are created. Position follows submission order.
    def rebuild_values(attribute)
      submitted = Array(params[:values]).map { |v| v.to_s.strip }.reject(&:empty?).uniq
      existing = attribute.variant_attribute_values.index_by(&:value)
      existing.each { |value, row| row.destroy unless submitted.include?(value) }
      submitted.each_with_index do |value, i|
        row = existing[value] || attribute.variant_attribute_values.build(value: value)
        row.update!(position: i)
      end
    end
  end
end
