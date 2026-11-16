# "Keep me posted" sign-ups (footer form or checkout tick-box), and the
# announcements the studio sends them from admin.
class CreateSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscribers do |t|
      t.string :email, null: false
      t.string :name
      t.string :token, null: false
      t.string :source, default: "footer", null: false
      t.string :sid
      t.datetime :unsubscribed_at
      t.timestamps
    end
    add_index :subscribers, :email, unique: true
    add_index :subscribers, :token, unique: true

    create_table :newsletters do |t|
      t.string :subject, null: false
      t.text :body, null: false
      t.string :button_label
      t.string :button_url
      t.string :status, default: "sending", null: false
      t.integer :recipients_count, default: 0, null: false
      t.integer :sent_count, default: 0, null: false
      t.integer :failed_count, default: 0, null: false
      t.datetime :finished_at
      t.timestamps
    end
  end
end
