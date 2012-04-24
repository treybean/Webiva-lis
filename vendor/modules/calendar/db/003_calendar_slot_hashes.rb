class CalendarSlotHashes < ActiveRecord::Migration
  def self.up
    add_column :calendar_slots, :slot_hash,:string
  end

  def self.down
    remove_column :calendar_slots, :slot_hash
  end

end
