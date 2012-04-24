

class CreditTypeClasses < ActiveRecord::Migration
  def self.up
    
    add_column :events_credit_types, :member_classes,:text
  end
  
  def self.down
    remove_column :events_credit_types,:member_classes
  end
end

