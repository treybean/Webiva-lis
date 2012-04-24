class LearningTag < ActiveRecord::Migration
  def self.up

    add_column :learning_modules, :activation_tags,:string  
  end

  def self.down
    remove_column :learning_modules,:activation_tags
  end

end
