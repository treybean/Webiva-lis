

class EventsRepeat  < DomainModel

  validates_presence_of :repeat_type,:start_time
  
  has_options :repeat_type,[ 
    ['Every Monday','monday'],
    ['Every Tuesday','tuesday'],
    ['Every Wednesday','wednesday'],
    ['Every Thursday','thursday'],
    ['Every Friday','friday'],
    ['Every Saturday','saturday'],
    ['Every Sunday','sunday'] ]
    
  has_options :repeat_type_day,[ 
    ['Monday','monday'],
    ['Tuesday','tuesday'],
    ['Wednesday','wednesday'],
    ['Thursday','thursday'],
    ['Friday','friday'],
    ['Saturday','saturday'],
    ['Sunday','sunday'] ]
    
  belongs_to :events_instructor
  belongs_to :map_location
            
  @@dows = %w(sunday monday tuesday wednesday thursday friday saturday sunday)
  
  attr_accessor :deleted
  
  has_many :events_events, :dependent => :nullify
  belongs_to :events_event

  include Events::TimeHelper
  def start_time_display
    time_display(self.start_time)
  end
  
  def after_create
    self.generate_events
  end
  
  def after_update
    self.events_events.find(:all,:conditions => 'event_on > NOW()').each do |event|
      event.reload(:lock => true)
      event.map_location_id = self.map_location_id unless self.map_location_id.blank?
      event.events_instructor_id = self.events_instructor_id unless self.events_instructor_id.blank?
      event.save
    end
  end
  
  def repeat_type_day; repeat_type; end
  
  def generate_events
    cur_date = (self.last_generated_date || self.start_on).to_time
    
    last_day = (Time.now + (self.events_event.days_advance+1).days).at_midnight
    
    # get the first weekday >= cur_date
    dest_dow = @@dows.index(self.repeat_type)
    cur_dow = cur_date.wday
    # calculate the offset to the first class day
    offset = dest_dow < cur_dow ? (7 - cur_dow + dest_dow) : (dest_dow - cur_dow) 
    cur_date += offset.days
    
    while(cur_date < last_day)
      event = self.events_event.clone
      event.update_attributes(:parent_event_id => self.events_event.id,
                              :events_repeat_id => self.id,
                              :events_instructor_id => self.events_instructor_id.blank? ? event.events_instructor_id : self.events_instructor_id,
                              :map_location_id => self.map_location_id.blank? ? event.map_location_id : self.map_location_id,
                              :repeat => false,
                              :event_bookings => 0,
                              :unconfirmed_bookings => 0,
                              :event_on => cur_date,
                              :start_time => self.start_time )
                              
      
      # add 7 days
      cur_date += 7.days
    end
    
    self.update_attribute(:last_generated_date,last_day)
  end
end
