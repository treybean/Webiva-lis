class LearningTables < ActiveRecord::Migration
  def self.up

    create_table :learning_modules, :force => true do |t|
      t.string :name
      t.integer :spacing_minutes
      t.text :description
      t.text :goals
      t.integer :reset_entries
      
      t.integer :program_image_id
      
      t.integer :content_template_id 
      t.integer :email_template_id
      
      t.boolean :hourly, :default => false

      t.timestamps

    end
    
    create_table :learning_sections, :force => true do |t|
      t.string :name
      t.integer :learning_module_id
      t.integer :position
      t.boolean :visible, :default => true
    end
    
    create_table :learning_lessons, :force => true do |t|
      t.integer :learning_module_id
      t.integer :learning_section_id
      t.string :title
      t.string :short_title
      t.integer :position
      t.integer :image_file_id
      t.integer :media_file_id
      t.text :data
      t.text :content
      t.text :content_html
      
      t.text :image_list
      t.text :email_content
      t.text :email_content_html
      
      t.integer :spacing_override_minutes
      
      t.timestamps
    end
    
    
    add_index :learning_lessons, :learning_module_id, :name => 'module'    
        
    create_table :learning_users, :force => true do |t|
      t.integer :learning_module_id
      t.integer :end_user_id
      t.boolean :started, :default => false
      t.boolean :finished, :default => false
      t.datetime :last_view_at
      
      t.datetime :last_lesson_at
      t.datetime :next_lesson_at
      t.integer :last_section_position
      t.integer :last_lesson_position
      t.integer :last_lesson_id
      
      t.timestamps
    end    
    
    create_table :learning_user_lessons, :force => true do |t|
      t.integer :learning_user_id
      t.integer :learning_section_id
      t.integer :learning_lesson_id
      t.integer :end_user_id
      t.text :data
      t.datetime :released_at
      t.datetime :first_view_at
      t.datetime :last_view_at
      t.integer :views
    end
  end

  def self.down
    drop_table :learning_modules
    drop_table :learning_sections
    drop_table :learning_lessons
    drop_table :learning_users
    drop_table :learning_user_lessons
  end

end
