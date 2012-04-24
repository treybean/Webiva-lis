

class EventsUserCredit < DomainModel

  belongs_to :events_credit_type
  belongs_to :end_user
  
  
  validates_presence_of :events_credit_type_id
  
  
  def self.get_events_user_credit(user,credit_type_id,options = {}) 
    credits = self.find_by_end_user_id_and_events_credit_type_id(user.id,credit_type_id, :lock => options[:lock])
    if !credits
      credits = self.create(:end_user_id => user.id, :events_credit_type_id => credit_type_id, :credits => 0)
      credits.reload(:lock => true) 
    end
    credits
  end
  
  def self.get_credits(user,credit_type_id)
    return 0 if credit_type_id.blank?
    self.get_events_user_credit(user,credit_type_id).credits
  end
  
  def self.refund_credit(user,credit_type_id,options = {})
    return false if credit_type_id.blank?
    credit_obj = self.get_events_user_credit(user,credit_type_id,:lock => true)
    credit_obj.update_attribute(:credits,credit_obj.credits+1)
    credit_entry(user,credit_type_id,1,"User Cancelled Class:" +  options[:description].to_s)
    return true
  end
  
  def self.use_credit!(user,credit_type_id,options = {}) 
    return false if credit_type_id.blank?
     credit_obj = self.get_events_user_credit(user,credit_type_id,:lock => true)
     if(credit_obj.credits > 0)
      credit_obj.update_attribute(:credits,credit_obj.credits-1)
      credit_entry(user,credit_type_id,-1,"User Booked Class:" + options[:description].to_s, :admin_user_id => options[:admin_user_id])
      return true
    else
      credit_obj.save
      return false
    end
  end
  
  def self.credit_adjustment!(user,credit_type_id,offset,message,options = {})
    credit_obj = self.get_events_user_credit(user,credit_type_id,:lock => true)
    credit_obj.update_attribute(:credits,credit_obj.credits+offset)
    credit_entry(user,credit_type_id,offset,message,options)
  end
  
  def self.credit_entry(user,credit_type_id,offset,message,options = {})
    EventsUserCreditEntry.create(:end_user_id => user.id,:events_credit_type_id => credit_type_id,:credit_difference => offset,
                                :description => message,  
                                :shop_order_id => options[:shop_order_id],
                                :admin_user_id => options[:admin_user_id])

  end

end
