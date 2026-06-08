module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: [ :edit, :update, :destroy ]

    def index
      @categories = Category.all
    end

    def new
      @category = Category.new(tone: Category::DEFAULT_TONE)
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to admin_categories_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @category.update(category_params)
        @category.image.purge if params.dig(:category, :remove_image) == "1"
        redirect_to admin_categories_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @category.destroy
      redirect_to admin_categories_path
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :blurb, :tone, :image)
    end
  end
end
