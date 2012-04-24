class InitialSetup < ActiveRecord::Migration
  def self.up
    create_table :notification_types, :force => true do |t|
      t.string :name
      t.integer :content_model_id
      t.boolean :default
    end

    create_table :notification_messages, :force => true do |t|
      t.integer :notification_type_id
      t.string :view_type
      t.integer :data_model_id
      t.integer :end_user_id
      t.boolean :has_tags, :default => false
      t.boolean :expired, :default => false
      t.datetime :starts_at
      t.datetime :expires_at
      t.datetime :created_at
    end

    add_index :notification_messages, :expired, :name => 'notification_message_expired_idx'
    add_index :notification_messages, :end_user_id, :name => 'notification_message_users_idx'

    create_table :notification_message_tags, :force => true do |t|
      t.integer :tag_id
      t.integer :notification_message_id
    end

    add_index :notification_message_tags, :tag_id, :name => 'notification_message_tag_idx'
    add_index :notification_message_tags, :notification_message_id, :name => 'notification_message_tag_msg_idx'

    create_table :notification_message_users, :force => true do |t|
      t.integer :end_user_id
      t.integer :notification_message_id
      t.boolean :cleared, :default => false
      t.datetimes
    end

    add_index :notification_message_users, :end_user_id, :name => 'notification_message_users_user_idx'
    add_index :notification_message_users, :notification_message_id, :name => 'notification_message_users_msg_idx'
  end

  def self.down
    drop_table :notification_types
    drop_table :notification_messages
    drop_table :notification_message_tags
    drop_table :notification_message_users
  end
end
