class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :price, null: false, default: 0
      t.integer :position, default: 0
      t.timestamps
    end

    create_table :variant_values do |t|
      t.references :variant, null: false, foreign_key: true
      t.references :variant_attribute_value, null: false, foreign_key: true
      t.timestamps
    end
    add_index :variant_values, [:variant_id, :variant_attribute_value_id], unique: true, name: "idx_variant_values_unique"
  end
end
