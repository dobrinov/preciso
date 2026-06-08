class AddToneToCategories < ActiveRecord::Migration[8.1]
  def up
    add_column :categories, :tone, :string

    # Backfill existing categories with their prototype tones.
    tones = {
      "bowls" => "#efe9e1", "cups" => "#ece6de", "espresso" => "#e9e2d8",
      "vases" => "#f0ebe4", "plates" => "#ece8e1"
    }
    Category.reset_column_information
    Category.find_each do |c|
      c.update_columns(tone: tones[c.slug] || "#ece6dd")
    end
  end

  def down
    remove_column :categories, :tone
  end
end
