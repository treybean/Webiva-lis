class InitialLocationTables < ActiveRecord::Migration
  def self.up

    create_table "map_locations", :force => true do |t|
      t.string "name"
      t.string "address"
      t.string "city"
      t.string "state"
      t.string "zip"
      t.string "phone"
      t.string "fax"
      t.string "website"
      t.text "description"
      t.decimal "lon", :precision => 11, :scale => 6
      t.decimal "lat", :precision => 11, :scale => 6
      t.string "identifier"
      t.text "overview_html"
      t.text "description_html"
      t.integer "locality_location_type_id"
      t.boolean "active", :default => false
      t.boolean "locked", :default => false
      t.text "image_list"
      t.string "hours"
      t.string "information"
    end

    add_index "map_locations", ["identifier"], :name => "Ident_Index"
    add_index :map_locations, [ :lat, :lon ], :name => 'position'
    
    
    create_table :map_location_types, :force => true do |t|
      t.string :name
      t.integer :domain_file_id
    end
    
    create_table :map_categories, :force => true do |t|
      t.string  :category
    end
    
    create_table :map_location_type_categories, :force => true do |t|
      t.integer :map_location_type_id
      t.integer :map_category_id
    end
    
    create_table :map_tags, :force => true do |t|
      t.string  :name
      t.integer :map_category_id
    end
    
    create_table :map_location_tags, :force => true do |t|
      t.integer :map_location_id
      t.integer :map_tag_id
    end
    
    
    create_table :map_zipcodes, :force => true do |t|
      t.string :zip
      t.string :city
      t.string :state
      t.decimal :latitude, :limit => 11, :precision => 11, :scale => 6
      t.decimal :longitude, :limit => 11, :precision => 11, :scale => 6
      t.integer :timezone
      t.boolean :dst
      t.string :country
    end
    
    add_index :map_zipcodes, :zip, :name => 'zip_index'
        
  end
  
  def self.down
    drop_table "map_locations"
    drop_table :map_location_types
    drop_table :map_location_type_categories
    drop_table :map_tags
    drop_table :map_location_tags
    drop_table :map_zipcodes
  end
end
