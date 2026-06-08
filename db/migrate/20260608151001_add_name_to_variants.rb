class AddNameToVariants < ActiveRecord::Migration[8.1]
  def change
    add_column :variants, :name, :string
  end
end
