class InitialCalendarSetup < ActiveRecord::Migration
  def self.up
  
    create_table :calendar_slot_groups, :force => true do |t|
      t.string :name
      t.string :color
    end
    
    create_table :calendar_slots, :force => true do |t|
      t.integer :calendar_slot_group_id
      t.string :color
      t.string :name
    end
    
    create_table :calendar_availabilities, :force=> true do |t|
      t.integer :calendar_slot_id
      t.string :availability_type
      t.date :start_on
      t.date :end_on
      t.integer :start_time
      t.integer :end_time
    end
    
    add_index :calendar_availabilities, [ :start_on, :end_on], :name => 'date_index'
    
    create_table :calendar_bookings, :force=> true do |t|
      t.integer :calendar_slot_id
      t.date :booking_on
      t.integer :start_time
      t.integer :end_time
      t.string :description
      t.string :booking_model_type
      t.string :booking_model_id
      t.datetime :valid_until
      t.boolean :confirmed, :default => false
      
      t.integer :end_user_id
      t.string :recipient_name
      
      t.timestamps
    end

    add_index :calendar_bookings, [ :booking_on], :name => 'date_index'

    
    create_table :calendar_holidays, :force => true do |t|
      t.date :start_on
      t.date :end_on
      t.integer :start_time
      t.integer :end_time
    end 

    add_index :calendar_holidays, [ :start_on, :end_on], :name => 'date_index'

    
    create_table :calendar_holiday_slots, :force => true do |t|
      t.integer :calendar_holiday_id
      t.integer :calendar_slot_id
    end
    
    add_index :calendar_holiday_slots, :calendar_holiday_id, :name => 'holiday_index'
    
  end

  def self.down
  end

end
