class AddIpAndUserAgentToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :ip, :string
    add_column :events, :user_agent, :string
  end
end
