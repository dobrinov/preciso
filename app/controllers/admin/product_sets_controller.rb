module Admin
  class ProductSetsController < BaseController
    before_action :set_set, only: [:edit, :update, :destroy]

    def index
      @sets = ProductSet.order(:id)
    end

    def new
      @set = ProductSet.new
    end

    def create
      @set = ProductSet.new(set_params)
      if @set.save
        rebuild_items(@set)
        attach_image(@set)
        redirect_to admin_sets_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @set.update(set_params)
        rebuild_items(@set)
        attach_image(@set)
        @set.image.purge if params[:remove_image] == "1"
        redirect_to admin_sets_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @set.destroy
      redirect_to admin_sets_path
    end

    private

    def set_set
      @set = ProductSet.find(params[:id])
    end

    def set_params
      params.require(:set).permit(:name, :price, :short, :long_desc)
    end

    # item_ids is an array of product ids (repeated for quantity); collapse to set_items.
    def rebuild_items(set)
      ids = Array(params.dig(:set, :item_ids)).reject(&:blank?)
      counts = ids.each_with_object({}) { |id, h| h[id] = (h[id] || 0) + 1 }
      set.set_items.destroy_all
      counts.each_with_index do |(pid, qty), i|
        next unless Product.exists?(pid)
        set.set_items.create!(product_id: pid, quantity: qty, position: i)
      end
    end

    def attach_image(set)
      set.image.attach(params[:set][:image]) if params.dig(:set, :image).present?
    end
  end
end
