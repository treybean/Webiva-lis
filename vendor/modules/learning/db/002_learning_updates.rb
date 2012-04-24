class LearningUpdates < ActiveRecord::Migration
  def self.up
  
    add_column :learning_users, :lesson_viewed, :boolean, :default => false
    add_column :learning_users, :first_warning_at, :datetime
    add_column :learning_users, :first_warning_triggered, :boolean, :default => false
    add_column :learning_users, :last_warning_at, :datetime
    add_column :learning_users, :last_warning_triggered, :boolean, :default => false

    add_column :learning_users, :data, :text
      
    add_index :learning_users, [ :end_user_id, :learning_module_id],:name => 'learning_user'
    
    add_column :learning_modules, :first_warning_days, :integer, :default => 3
    add_column :learning_modules, :last_warning_days, :integer, :default => 7
    add_column :learning_modules, :first_warning_template_id, :integer
    add_column :learning_modules, :last_warning_template_id, :integer
    
   
  end

  def self.down
    remove_column :learning_users, :lesson_viewed
    remove_column :learning_users, :first_warning_at
    remove_column :learning_users, :last_warning_at
    remove_column :learning_users, :first_warning_triggered
    remove_column :learning_users, :last_warning_triggered
    
    remove_column :learning_users, :data, :text
    
    remove_column :learning_modules, :first_warning_days
    remove_column :learning_modules, :last_warning_days
    remove_column :learning_modules, :first_warning_template_id
    remove_column :learning_modules, :last_warning_template_id
    
  
    remove_index :learning_users,:name => 'learning_user'
  end

end
