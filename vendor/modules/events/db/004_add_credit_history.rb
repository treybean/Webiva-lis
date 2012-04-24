

class AddCreditHistory < ActiveRecord::Migration
  def self.up
    
    create_table :events_user_credit_entries do |t|
      t.integer :events_credit_type_id
      t.integer :end_user_id
      t.integer :credit_difference
      t.string  :description
      t.integer :admin_user_id
      t.integer :shop_order_id
      t.datetime :created_at
    end
  end
  
  def self.down
    drop_table :events_user_credit_entries
  end
end

