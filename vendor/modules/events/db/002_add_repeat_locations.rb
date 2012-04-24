

class AddRepeatLocations < ActiveRecord::Migration
  def self.up
    add_column :events_repeats, :map_location_id, :integer
  end
  
  def self.down
    remove_column :events_repeats, :map_location_id
  end
end

