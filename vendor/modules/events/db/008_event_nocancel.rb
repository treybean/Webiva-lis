

class EventNocancel < ActiveRecord::Migration
  def self.up
    
    add_column :events_events, :no_cancel, :boolean, :default => false
  end
  
  def self.down
    remove_column :events_events, :no_cancel
    
  end
end

