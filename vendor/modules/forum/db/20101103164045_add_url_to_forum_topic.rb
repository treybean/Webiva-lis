class AddUrlToForumTopic < ActiveRecord::Migration
  def self.up
    add_column :forum_topics, :permalink, :string
    add_index :forum_topics, :permalink
  end

  def self.down
    remove_column :forum_topics, :permalink
  end
end
