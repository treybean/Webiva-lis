

class EventAddedFields < ActiveRecord::Migration
  def self.up
    
    add_column :events_events, :start_at, :datetime
    add_column :events_events, :end_at, :datetime
    add_column :events_events, :cost_override, :decimal, :precision=> 14, :scale => 2
    add_column :events_events, :member_cost_override, :decimal, :precision=> 14, :scale => 2
    add_column :events_events, :open_booking, :boolean, :default => false
    add_column :events_events, :lon, :decimal, :precision => 11, :scale => 6
    add_column :events_events, :lat, :decimal, :precision => 11, :scale => 6
    
    add_index :events_events, [ :lat, :lon ], :name => 'position'
    
    
  end
  
  def self.down
    remove_column :events_events, :start_at
    remove_column :events_events, :end_at
    remove_column :events_events, :cost_override
    remove_column :events_events, :member_cost_override
    remove_column :events_events, :open_booking
    remove_column :events_events, :lat
    remove_column :events_events, :lon
    
    remove_index :events_events, :name => 'position'
  end
end

