class AddFeaturedToHomePages < ActiveRecord::Migration[8.1]
  def change
    add_column :home_pages, :featured_kind, :string
    add_column :home_pages, :featured_id, :integer
  end
end
