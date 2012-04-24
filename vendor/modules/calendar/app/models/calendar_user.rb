
class CalendarUser < DomainModel

  belongs_to :end_user
  has_many :calendar_user_credits
  
  validates_presence_of :end_user_id
  validates_uniqueness_of :end_user_id
  
  def before_save
   self.ical_hash = CalendarUser.generate_hash if self.ical_hash.blank?
    
  end


  def self.user(usr,options = {})
     cu = self.find_by_end_user_id(usr.id,:lock => options[:lock])
     if !cu
      cu = self.create(:end_user_id => usr.id)
      cu.reload(:lock => true) if options[:lock]
     end
     cu
  end
  
  def self.update_credits(usr,offset,message,options = {})
    CalendarUser.transaction do
      cu = self.user(usr,:lock => true)
      cu.update_attribute(:credits,cu.credits + offset)
      CalendarUserCredit.create(:calendar_user_id => cu.id,:end_user_id => usr.id,:credit_difference => offset,
                                :description => message,  
                                :shop_order_id => options[:shop_order_id],
                                :admin_user_id => options[:admin_user_id])
    end
  end
  
end
