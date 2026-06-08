module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:edit, :update, :destroy]

    def index
      @categories = Category.all
      @products = Product.includes(:category, images_attachments: :blob).order(:id)
    end

    def new
      @product = Product.new(category: Category.first)
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        attach_images
        redirect_to admin_products_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @product.update(product_params)
        purge_images
        attach_images
        redirect_to admin_products_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :category_id, :price, :short, :long_desc)
    end

    def attach_images
      files = Array(params.dig(:product, :images)).reject(&:blank?)
      @product.images.attach(files) if files.any?
    end

    def purge_images
      ids = Array(params[:remove_image_ids]).reject(&:blank?)
      @product.images.attachments.where(id: ids).find_each(&:purge) if ids.any?
    end
  end
end
