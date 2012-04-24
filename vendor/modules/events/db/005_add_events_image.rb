

class AddEventsImage < ActiveRecord::Migration
  def self.up
    
    add_column :events_events, :icon_file_id, :integer
  end
  
  def self.down
    remove_column :events_events, :icon_file_id
  end
end

