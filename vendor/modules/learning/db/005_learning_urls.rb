class LearningUrls < ActiveRecord::Migration
  def self.up

    add_column :learning_modules, :page_url, :string
  end

  def self.down
    remove_column :learning_modules,:page_url
  end

end
