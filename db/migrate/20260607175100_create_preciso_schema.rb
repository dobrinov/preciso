class CreatePrecisoSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :blurb
      t.integer :position, default: 0
      t.timestamps
    end
    add_index :categories, :slug, unique: true

    create_table :products do |t|
      t.string :name, null: false
      t.references :category, foreign_key: true
      t.integer :price, null: false, default: 0
      t.string :short
      t.text :long_desc
      t.timestamps
    end

    create_table :product_sets do |t|
      t.string :name, null: false
      t.integer :price, null: false, default: 0
      t.string :short
      t.text :long_desc
      t.timestamps
    end

    create_table :set_items do |t|
      t.references :product_set, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :position, default: 0
      t.timestamps
    end

    create_table :orders do |t|
      t.string :number, null: false
      t.string :status, null: false, default: "new"
      t.string :customer_name
      t.string :customer_email
      t.string :customer_phone
      t.text :note
      t.integer :total, null: false, default: 0
      t.timestamps
    end
    add_index :orders, :number, unique: true

    create_table :order_lines do |t|
      t.references :order, null: false, foreign_key: true
      t.string :kind, null: false, default: "product"
      t.string :item_id
      t.string :name
      t.integer :price, null: false, default: 0
      t.integer :qty, null: false, default: 1
      t.timestamps
    end

    create_table :abouts do |t|
      t.string :title
      t.text :lead
      t.text :body
      t.string :signature
      t.string :studio
      t.timestamps
    end

    create_table :events do |t|
      t.string :event_type, null: false
      t.string :sid
      t.string :page_key
      t.string :label
      t.boolean :piece, default: false
      t.string :name
      t.integer :total
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :events, :event_type
    add_index :events, :occurred_at
  end
end
