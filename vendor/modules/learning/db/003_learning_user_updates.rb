class LearningUserUpdates < ActiveRecord::Migration
  def self.up
    
    create_table :learning_data_entries, :force =>true do |t|
      t.integer :learning_user_id
      t.integer :end_user_id
      t.text :data    
    end
    
    add_index :learning_data_entries, :learning_user_id, :name => 'lu'
   
  end

  def self.down
    drop_table :learning_data_entries
  end

end
