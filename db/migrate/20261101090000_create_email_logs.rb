class CreateEmailLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :email_logs do |t|
      t.references :order, foreign_key: true
      t.string :kind, null: false      # OrderMailer action, e.g. "paid"
      t.string :recipient
      t.string :subject
      t.string :status, null: false    # queued | sent | failed | skipped
      t.string :detail                 # error message / why skipped
      t.timestamps
    end
  end
end
