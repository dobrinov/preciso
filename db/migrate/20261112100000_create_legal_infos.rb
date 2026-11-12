class CreateLegalInfos < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_infos do |t|
      t.string :company_name
      t.string :company_id
      t.string :vat_number
      t.string :address
      t.string :email
      t.string :phone
      t.text :terms
      t.text :refund_policy
      t.text :return_policy
      t.text :cancellation_policy
      t.text :delivery_terms
      t.timestamps
    end
  end
end
