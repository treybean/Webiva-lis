class InitialForumSetup < ActiveRecord::Migration
  def self.up

    create_table :forum_categories, :force => true do |t|
      t.string :name
      t.string :url
      t.text :description
      t.integer :weight, :default => 0

      t.string :content_filter
      t.integer :folder_id
      t.boolean :allow_attachments,:default => true
      t.integer :file_size_limit
      t.boolean :admin_permission,:default => false
      t.boolean :allow_anonymous_posting, :default => true
      t.boolean :post_permission,:default => false
      t.integer :subscription_template_id

    end

    create_table :forum_forums, :force => true do |t|
      t.integer :parent_id
      t.string :name
      t.string :url
      t.integer :weight, :default => 0
      
      t.integer :forum_category_id
      t.integer :image_id
      t.text :description
      

      t.integer :forum_topics_count, :default => 0
      t.boolean :main_page, :default => false

      t.timestamps
    end
    
    create_table :forum_topics, :force => true do |t|
      t.integer :forum_forum_id
      t.integer :end_user_id
      t.string :posted_by
      t.string :subject
      t.integer :forum_posts_count, :default => 0
      t.integer :last_post_id
      t.datetime :last_posted_at
      t.integer :activity_count, :default => 0
      t.integer :views_count, :default => 0
      t.string :content_type
      t.integer :content_id

      t.integer :sticky, :default => 0

      t.timestamps
    end
    
    add_index :forum_topics, [ :forum_forum_id, :created_at ], :name => 'forum_forum_id'
    add_index :forum_topics, [ :forum_forum_id, :last_posted_at, :activity_count ], :name => 'forum_activity'
    add_index :forum_topics, [ :content_type, :content_id ], :name => 'topic_content'
    
    create_table :forum_posts, :force => true do |t|
      t.boolean :first_post, :default => false
      t.integer :forum_forum_id
      t.integer :forum_topic_id
      t.integer :end_user_id
      t.string :posted_by
      t.string :subject
      t.text :body, :limit => 2.megabytes
      t.text :body_html , :limit => 2.megabytes
      
      t.boolean :approved, :default => true
      t.datetime :moderated_at
      t.integer :moderated_by_id
      t.datetime :posted_at
      t.datetime :edited_at
    end
    
    add_index :forum_posts, [ :forum_topic_id, :posted_at ], :name => 'topic_posted'
    add_index :forum_posts, [ :posted_at ], :name => 'posted_at'

    create_table :forum_post_attachments, :force => true do |t|
      t.integer :forum_post_id
      t.integer :end_user_id
      t.integer :domain_file_id
    end

    add_index :forum_post_attachments, :forum_post_id, :name => 'forum_post_id'
    add_index :forum_post_attachments, :end_user_id, :name => 'user'

    create_table :forum_subscriptions, :force => true do |t|
      t.integer :end_user_id
      t.integer :forum_topic_id
      t.integer :forum_forum_id
    end
    
    add_index :forum_subscriptions, :forum_topic_id, :name => 'forum_topic_id'
    add_index :forum_subscriptions, [ :forum_forum_id, :forum_topic_id ], :name => 'forum_forum_id'
  end
   
  def self.down
    drop_table :forum_categories
    drop_table :forum_forums
    drop_table :forum_topics
    drop_table :forum_posts
    drop_table :forum_subscriptions
    drop_table :forum_post_attachments
  end

end
