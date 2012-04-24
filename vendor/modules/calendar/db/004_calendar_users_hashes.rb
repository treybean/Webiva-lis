class CalendarUsersHashes < ActiveRecord::Migration
  def self.up
    add_column :calendar_users, :ical_hash, :string
  end

  def self.down
    remove_column :calendar_users, :ical_hash
  end

end
