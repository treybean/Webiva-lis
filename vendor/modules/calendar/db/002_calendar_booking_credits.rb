class CalendarBookingCredits < ActiveRecord::Migration
  def self.up
    create_table :calendar_users, :force => true do |t|
      t.integer :end_user_id
      t.integer :credits, :default => 0
    end
    
    add_index :calendar_users, :end_user_id, :name => 'user_index'
    
    create_table :calendar_user_credits, :force => true do |t|
      t.integer :calendar_user_id
      t.integer :end_user_id
      t.integer :credit_difference
      t.string  :description
      t.integer :admin_user_id
      t.integer :shop_order_id
      t.datetime :created_at
    end
    
    add_index :calendar_user_credits, [ :end_user_id, :created_at ], :name => 'user_index'
    add_index :calendar_user_credits, :created_at, :name => 'date_index'
  end

  def self.down
    drop_table :calendar_users
    drop_table :calendar_user_credits
  end

end
