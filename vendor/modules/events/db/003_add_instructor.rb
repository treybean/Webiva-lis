

class AddInstructor < ActiveRecord::Migration
  def self.up
    
    create_table :events_instructors do |t|
      t.string :name
      t.integer :image_file_id
      t.integer :end_user_id
      t.text :description
      t.text :details
    end
    
    remove_column :events_repeats, :by
    add_column :events_repeats, :events_instructor_id, :integer
    
    remove_column :events_events, :by
    add_column :events_events, :events_instructor_id, :integer
  end
  
  def self.down
    drop_table :events_instructors

    add_column :events_repeats, :by, :string
    remove_column :events_repeats, :events_instructor_id
    
    add_column :events_events, :by, :string
    remove_column :events_events, :events_instructor_id
  end
end

