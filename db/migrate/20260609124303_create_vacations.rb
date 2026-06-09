class CreateVacations < ActiveRecord::Migration[8.1]
  def change
    create_table :vacations do |t|
      t.boolean :active, null: false, default: false
      t.text :message
      t.timestamps
    end
  end
end
