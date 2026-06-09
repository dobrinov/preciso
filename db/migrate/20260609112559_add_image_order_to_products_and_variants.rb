class AddImageOrderToProductsAndVariants < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :image_order, :text
    add_column :variants, :image_order, :text
  end
end
