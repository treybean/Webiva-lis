class Intial < ActiveRecord::Migration
  def self.up
    create_table :rewards_users, :force => true do |t|
      t.integer :end_user_id
      t.integer :rewards, :default => 0
      t.timestamps
    end

    add_index :rewards_users, :end_user_id

    create_table :rewards_transactions, :force => true do |t|
      t.integer :rewards_user_id
      t.integer :end_user_id
      t.integer :amount
      t.string :transaction_type
      t.boolean :used, :default => false
      t.text :note
      t.integer :admin_user_id
      t.timestamps
    end

    add_index :rewards_transactions, :rewards_user_id
    add_index :rewards_transactions, :end_user_id
  end

  def self.down
    drop_table :rewards_users
    drop_table :rewards_transactions
  end
end
