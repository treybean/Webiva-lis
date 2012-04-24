class CalendarAvailability < DomainModel

  belongs_to :calendar_slot
  
  has_options :availability_type, 
              [ ['Once','once'], 
                ['Daily','daily'],
                ['Weekdays','weekdays'],
                ['Weekends','weekends'],
                ['Weekly','weekly'],
                ['Monthly','monthly']
              ]
              
            
  validates_presence_of :availability_type, :calendar_slot_id, :start_time, :end_time, :start_on
  
  
  def self.time_select_options()
    tm = Time.now.at_midnight
    end_time = tm.tomorrow
    output = []
    while(tm < end_time) do
      output << [ tm.strftime("%I:%M %p".t), tm.seconds_since_midnight / 60 ]
      tm += 15.minutes
    end
    output
 end
 
 def start_time_str
  Calendar::Utility.time_str(start_time)
 end
 
 def end_time_str
  Calendar::Utility.time_str(end_time)
 end
 
 def get_color
  self.calendar_slot.color
 end
 
 
 def between(start_day,end_day,&block) 
  cur_day = first_date(start_day)
   while(cur_day && cur_day <= end_day && (!self.end_on || cur_day < (self.end_on.to_time+1.days)))
    yield cur_day
    
    cur_day = first_date(cur_day.tomorrow)
    cur_day = cur_day.at_midnight if cur_day
  end
 end
 
 def first_date(starting_day)
  case availability_type
  when 'once'
    (starting_day.to_date <= start_on.to_date) ? start_on.to_time : nil
  when 'daily'
    (starting_day.to_date <= start_on.to_date) ? start_on.to_time : starting_day
  when 'weekdays'
    dow = starting_day.strftime("%w").to_i
    if(dow == 0) # Sunday
      starting_day.tomorrow
    elsif(dow == 6) # Saturday
      starting_day.tomorrow.tomorrow
    else
      starting_day
    end
  when 'weekends'
    dow = starting_day.strftime("%w").to_i
    if(dow == 0 || dow == 6)
      starting_day
    else
      starting_day + (6-dow).days
    end
  when 'weekly'
    dow = starting_day.strftime("%w").to_i
    start_dow = self.start_on.strftime("%w").to_i
    if start_dow < dow
      starting_day + (start_dow - dow + 7).days
    else 
      starting_day + (start_dow - dow).days
    end
  else 
    raise "Unsupported Date"
  end
 
 end
 
 
 
 def description
  case availability_type
  when 'once':
    sprintf("Once %s to %s".t,start_time_str,end_time_str)
  when 'daily':
    sprintf("Every day %s to %s".t, start_time_str,end_time_str)
  when 'weekdays':
    sprintf("Weekdays (M-F) %s to %s".t, start_time_str,end_time_str)
  when 'weekends':
    sprintf("Weekends (Sat-Sun) %s to %s".t, start_time_str,end_time_str)
  when 'weekly':
    sprintf("Every %s, %s to %s".t,self.start_on.strftime("%A"),start_time_str,end_time_str)
  else 
    'unsupported'
  end
 end
 
 
 def get_color
  self.calendar_slot.color
 end
 
 def get_description(start_time,end_time,options = {})
  sprintf("%s available %s to %s".t,options[:override] || self.calendar_slot.name,Calendar::Utility.time_str(start_time),Calendar::Utility.time_str(end_time))
 end
 
 
 
end
