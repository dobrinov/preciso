module Admin
  class CollectionsController < BaseController
    before_action :set_collection, only: [ :edit, :update, :destroy ]

    def index
      @collections = Collection.all
    end

    def new
      @collection = Collection.new
    end

    def create
      @collection = Collection.new(collection_params)
      if @collection.save
        rebuild_members(@collection)
        attach_cover(@collection)
        redirect_to admin_collections_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @collection.update(collection_params)
        rebuild_members(@collection)
        attach_cover(@collection)
        @collection.cover.purge if params.dig(:collection, :remove_cover) == "1"
        redirect_to admin_collections_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @collection.destroy
      redirect_to admin_collections_path
    end

    private

    def set_collection
      @collection = Collection.find(params[:id])
    end

    def collection_params
      params.require(:collection).permit(:name, :description)
    end

    def rebuild_members(collection)
      ids = Array(params.dig(:collection, :product_ids)).reject(&:blank?).uniq
      collection.collection_memberships.destroy_all
      ids.each_with_index do |pid, i|
        next unless Product.exists?(pid)
        collection.collection_memberships.create!(product_id: pid, position: i)
      end
    end

    def attach_cover(collection)
      collection.cover.attach(params[:collection][:cover]) if params.dig(:collection, :cover).present?
    end
  end
end
