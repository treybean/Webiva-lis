

class CalendarHoliday < DomainModel

  has_many :calendar_holiday_slots
  validates_presence_of :start_on
  
  def calendar_slot_ids
    self.calendar_holiday_slots.collect(&:calendar_slot_id)  
  end
  
  def calendar_slot_ids=(val)
    @slot_cache = val
  end
  
  def after_save
   if @slot_cache
     self.calendar_holiday_slots = []
     @slot_cache.each do |slot_id|
       self.calendar_holiday_slots.create(:calendar_slot_id => slot_id)
     end
   end
  end
  
  def get_color
    self.id ? "#DDDDDD" : "#FFFFFF"
  end
  
  def get_description(start_time,end_time,options = {})
    self.id ? "Holiday" : ""
  end
  
  def recipient_name
    self.id ? "Holiday" : ""
  end
  
  def between(start_day,end_day,&block) 
    cur_day = start_on.to_time.at_midnight
    cur_day = start_day if(cur_day < start_day)
    
    end_at = (end_on || end_day).to_time.at_midnight + 1.days
      
    while(cur_day && (cur_day <= end_day) && (cur_day < end_at))
      yield cur_day
      
      cur_day = cur_day.tomorrow
    end
 end
  
end
