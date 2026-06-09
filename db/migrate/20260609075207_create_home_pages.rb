class CreateHomePages < ActiveRecord::Migration[8.1]
  def change
    create_table :home_pages do |t|
      t.string :hero_eyebrow
      t.text :hero_title
      t.string :hero_accent
      t.text :hero_subtext
      t.string :maker_eyebrow
      t.string :maker_title
      t.text :maker_text
      t.text :footer_blurb

      t.timestamps
    end
  end
end
