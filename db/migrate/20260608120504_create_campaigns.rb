class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :active, null: false, default: false
      t.text :blurb
      t.timestamps
    end
    add_index :campaigns, :slug, unique: true
    add_index :campaigns, :active

    create_table :campaign_items do |t|
      t.references :campaign, null: false, foreign_key: true
      t.string :kind, null: false, default: "product"
      t.integer :item_id, null: false
      t.string :discount_kind, null: false, default: "fixed"
      t.integer :sale_price
      t.integer :percent_off
      t.timestamps
    end
    add_index :campaign_items, [ :kind, :item_id ]
  end
end
