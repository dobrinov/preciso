class AddVariantToOrderLines < ActiveRecord::Migration[8.1]
  def change
    add_column :order_lines, :variant_id, :integer
    add_column :order_lines, :variant_label, :string
  end
end
