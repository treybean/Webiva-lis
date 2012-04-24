
class InitialEventSetup < ActiveRecord::Migration
  def self.up
  
    create_table :events_credit_types, :force => true do |t|
      t.string :name
      t.decimal :standard_cost, :precision=> 14, :scale => 2
      t.decimal :member_cost, :precision=> 14, :scale => 2
    end
    
    create_table :events_repeats, :force => true do |t|
      t.integer :events_event_id
      t.string :repeat_type
      t.string :repeat_details
      t.integer :start_time
      t.date   :start_on
      t.date   :last_generated_date
      t.string :by
      t.string :location
    end
    
    create_table :events_events, :force => true do |t|
      t.integer :parent_event_id
      t.integer :events_repeat_id
      
      t.string :name
      t.string :subtitle
      t.string :by
      t.string :location
      t.integer :map_location_id
      t.integer :image_file_id
      t.integer :document_file_id
      t.date :event_on
      t.integer :start_time
      t.integer :duration
      t.boolean :canceled, :default => false
      
      t.integer :events_credit_type_id
      
      t.text  :description
      t.text :details
      t.text :note
      
      t.boolean :repeat, :default => false
      t.integer :days_advance
      
      t.integer :event_spaces, :default => 0
      t.integer :event_bookings, :default => 0
      
      t.integer :unconfirmed_bookings, :default => 0
      t.datetime :last_unconfirmed_check
      
      t.integer :admin_user_id
    end 
    
    create_table :events_bookings, :force => true do |t|
      t.integer :events_event_id
      t.integer :end_user_id
      t.datetime :valid_until
      t.boolean :confirmed, :default => false
      t.timestamps
    end        
    
    add_index :events_bookings, [ :end_user_id,:events_event_id,  ], :name => 'event_user'
    add_index :events_bookings, [ :events_event_id, :confirmed,:valid_until ], :name => 'event_confirmed'
    
    create_table :events_user_credits do |t|
      t.integer :end_user_id
      t.integer :events_credit_type_id
      t.integer :credits
    end
  end

  def self.down
    drop_table :events_credit_types
    drop_table :events_repeats
    drop_table :events_events
    drop_table :events_bookings
    drop_table :events_user_credits
  end

end
