class CreateVariantAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_attributes do |t|
      t.string :name, null: false
      t.integer :position, default: 0
      t.timestamps
    end

    create_table :variant_attribute_values do |t|
      t.references :variant_attribute, null: false, foreign_key: true
      t.string :value, null: false
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
