

class AddLocationImages < ActiveRecord::Migration
  def self.up
    add_column :map_locations, :image_id, :integer
  end
  
  def self.down
    remove_column :map_locations, :image_id
  end
end

