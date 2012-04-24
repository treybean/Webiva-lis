

class EventPrivate < ActiveRecord::Migration
  def self.up
    
    add_column :events_events, :is_private, :boolean, :default => false
  end
  
  def self.down
    remove_column :events_events, :is_private
    
  end
end

