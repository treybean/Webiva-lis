

class EventTypeTarget < ActiveRecord::Migration
  def self.up
    
    add_column :events_events, :target_type, :string,:size => 32
    add_column :events_events, :target_id, :integer
    
    add_index :events_events,  [:target_type,:target_id ], :name => 'target_index'
    add_index :events_events, [:event_on], :name => 'date_index'
  end
  
  def self.down
    remove_column :events_events, :target_type
    remove_column :events_events, :target_id

    remove_index :name => 'target_index'
    
  end
end

