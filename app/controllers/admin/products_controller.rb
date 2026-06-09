module Admin
  class ProductsController < BaseController
    include ImageReordering
    before_action :set_product, only: [ :edit, :update, :destroy ]

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
        apply_product_images
        redirect_to admin_products_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @product.update(product_params)
        apply_product_images
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

    def apply_product_images
      apply_images(@product, files: params.dig(:product, :images),
                             remove_ids: params[:remove_image_ids],
                             tokens: params[:image_order_tokens].to_s.split(","))
    end
  end
end
