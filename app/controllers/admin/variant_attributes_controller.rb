module Admin
  class VariantAttributesController < BaseController
    before_action :set_attribute, only: [ :edit, :update, :destroy ]

    def index
      @attributes = VariantAttribute.all
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

    # Replace values from the submitted list. Update existing rows in place by
    # index (so variant references to a value survive a rename), create new
    # rows for extras, and delete rows beyond the submitted count.
    def rebuild_values(attribute)
      submitted = Array(params[:values]).map(&:to_s).map(&:strip).reject(&:empty?)
      existing = attribute.variant_attribute_values.to_a
      submitted.each_with_index do |val, i|
        if (row = existing[i])
          row.update!(value: val, position: i)
        else
          attribute.variant_attribute_values.create!(value: val, position: i)
        end
      end
      existing[submitted.size..]&.each(&:destroy)
    end
  end
end
