

class EventsEvent  < DomainModel


  validates_numericality_of :event_spaces, :start_time,:duration
  validates_presence_of :name
  validates_date :event_on
  
  belongs_to :map_location
  
  attr_accessor :repeat_values
  
  has_many :events_repeats, :dependent => :destroy
  belongs_to :parent_repeat, :foreign_key => 'events_repeat_id', :class_name => 'EventsRepeat'
  belongs_to :parent_event, :class_name => 'EventsEvent', :foreign_key => 'parent_event_id'
  
  belongs_to :events_instructor
  
  has_many :child_events, :foreign_key => 'parent_event_id', :class_name => 'EventsEvent',  :dependent => :nullify
  belongs_to :events_credit_type
  belongs_to :image_file, :class_name => 'DomainFile', :foreign_key => :image_file_id
  belongs_to :icon_file, :class_name => 'DomainFile', :foreign_key => :icon_file_id
  belongs_to :document_file, :class_name => 'DomainFile'
  has_many :events_bookings, :include => [ :end_user ], :dependent => :destroy
  has_many :confirmed_bookings, :include => [ :end_user ],:class_name => 'EventsBooking', :foreign_key => 'events_event_id',:conditions => 'confirmed = 1'
  
  has_options :duration, 
                    [[ '15 Minutes', 15],
                     [ '30 Minutes', 30],
                     [ '45 Minutes',45],
                     [ '1 Hour',60],
                     [ '1 Hour 15 Minutes',75],
                     [ '1 Hour 30 Minutes',90],
                     [ '1 Hour 45 Minutes',105],
                     [ '2 Hours',120],
                     [ '2 Hour 15 Minutes',135],
                     [ '2 Hour 30 Minutes',150],
                     [ '2 Hour 45 Minutes',165],
                     [ '3 Hours',180],
                     [ '3 Hour 15 Minutes',195],
                     [ '3 Hour 30 Minutes',210],
                     [ '3 Hour 45 Minutes',225],
                     [ '4 Hours',240]
                     
                     ]
  belongs_to :target, :polymorphic => true
  
  
  def before_save
    if self.map_location 
      self.location = self.map_location.name
      self.lat = self.map_location.lat
      self.lon = self.map_location.lon
    end
    self.start_at  = self.event_starts_at
    self.end_at = self.event_ends_at
    

  end
                     
  def by
    self.events_instructor ? self.events_instructor.name : ''
  end

  def short_description  
      dsc = sprintf("%s on %s at %s",self.name,self.event_on.strftime(DEFAULT_DATE_FORMAT.t),self.start_time_display)
  end

  
  def self.time_select_options()
    tm = Time.mktime(2008,01,01).at_midnight + 1.days
    end_time = tm.tomorrow
    output = []
    while(tm < end_time) do
      output << [ tm.strftime("%I:%M %p".t), tm.seconds_since_midnight / 60 ]
      tm += 15.minutes
    end
    output
 end
 
  include Events::TimeHelper
  def start_time_display(override = nil)
    time_display(override || self.start_time)
  end
  def end_time_display
    time_display(self.start_time + self.duration)
  end
  
  
  def event_starts_at; time_calc(self.event_on,self.start_time); end
  def event_ends_at; time_calc(self.event_on,self.start_time + self.duration); end
  
  
  def take_over_repeating!
    self.parent_repeat.events_events.find(:all,:lock => true).each do |evt|
      evt.update_attribute(:parent_event_id,self.id)    
    end
    
  end
 
 
   def repeats
    if @repeat_cache
       @repeat_cache.collect do |elm| 
        elm = elm.clone
        rep = EventsRepeat.find_by_id(elm[:id]) || self.events_repeats.build
        # Use EventsRepeat instead of self.events_repeats because we might be changing
        # the parent of the events repeat 
        elm.delete(:id)
        rep.attributes = elm
        rep.events_event_id = self.id
        rep
      end    
    else
      self.events_repeats
    end
  end
  
  def repeats=(val)
     @repeat_cache = (val||[]).collect { |elm| elm.delete(:id) if elm[:id].blank?; elm }
  end
 
 
  def after_save
    if @repeat_cache
      repeat_list = []
      @repeat_cache.each_with_index do |elm,idx|
        rep = EventsRepeat.find_by_id(elm[:id]) || self.events_repeats.build
        # Use EventsRepeat instead of self.events_repeats because we might be changing
        # the parent of the events repeat 
        elm.delete(:id)
        rep.attributes = elm
        if rep.deleted.blank?
          rep.save
          repeat_list << rep
        elsif rep.id
          rep.events_events.each { |evt| evt.destroy } if rep.deleted == 'destroy'
          rep.destroy
        end
      end
      self.events_repeats = repeat_list
    end    
    
    
    if(self.repeat?)
      self.child_events.find(:all,:conditions => [ "event_on > ?",Time.now],:include => :parent_repeat,:lock => true).each do |event|
        event.update_attributes(:name => self.name,
                                :subtitle => self.subtitle,
                                # Only update the by if it's not controlled by the repeating processes
                                :events_instructor_id => (event.events_instructor_id && !event.parent_repeat.events_instructor_id.blank?) ? event.events_instructor_id : self.events_instructor_id,
                                :location => (event.parent_repeat && !event.parent_repeat.location.blank?) ? event.location : self.location,
                                :duration => self.duration,
                                :description => self.description,
                                :details => self.details,
                                :event_spaces => self.event_spaces,
                                :events_credit_type_id => self.events_credit_type_id,
                                :image_file_id => self.image_file_id,
                                :icon_file_id => self.icon_file_id)
      end
    end
      
  end
  

 # Return an array of each day between start and end time with all the events on that day 
 def self.event_schedule(start_time,end_time,options={}) 
  events_hash = []
  with_scope(:find => options) do 
    events_hash = self.find(:all,:conditions => [ 'event_on BETWEEN ? AND ?',start_time.to_date,end_time.to_date],:order => 'start_time', :include => [ :map_location, :events_instructor ] ).group_by do |evt|
                    evt.event_on.strftime(DEFAULT_DATE_FORMAT.t)
                  end
  end
  
  event_arr = []
  cur_time = start_time
  while(cur_time < end_time)
    cur_date = cur_time.strftime(DEFAULT_DATE_FORMAT.t)
    event_arr << { :time => cur_time, :date  => cur_date, :events => events_hash[cur_date] || [] }
    
    cur_time += 1.day
    cur_time = cur_time.at_midnight
  end
  
  event_arr 
 end
 
 def self.event_list(start_time,end_time,options={})

  evt_list = []
   
  with_scope(:find => options) do 
    evt_list = self.find(:all,:conditions => [ 'event_on BETWEEN ? AND ?',start_time.to_date,end_time.to_date],:order => 'events_events.name', :include => [ :map_location, :events_instructor, :image_file, :icon_file ] )
  end
  
  event_id_hash = {}
  
  event_arr = []
  cur_time = start_time
  evt_list.each do |evt|
    cur_parent = evt.parent_event_id.blank? ? evt.id : evt.parent_event_id
    if !event_id_hash[cur_parent]
      event_arr << evt
      event_id_hash[cur_parent] = true
    end
  end
  
  event_arr
 end

 def self.week_schedule(start_time) 
   first_day = start_time.at_beginning_of_week
   last_day = first_day + 7.days 
   
   all_events = self.find(:all,:conditions => [ 'event_on BETWEEN ? AND ?',first_day.to_date,last_day.to_date],:order => 'start_time', :include => :map_location)
   
   evt_hash = all_events.group_by(&:start_time)
   start_times = evt_hash.keys.sort
   
   days_list = (0..6).collect { |idx| dy = (first_day + idx.days); [ dy.strftime(DEFAULT_DATE_FORMAT.t),dy ] }

   
   evt_list = start_times.collect do |time|
    day_hash = evt_hash[time].group_by { |evt| evt.event_on.strftime(DEFAULT_DATE_FORMAT.t) }
    
    days = days_list.collect do |day|
      { :day => day[0], :date => day[1], :events => day_hash[day[0]] || {} }
    end
    { :time => time, :days => days }    
   end

    return [ days_list, evt_list ]
 end
 
 def self.weekly_schedule(start_time,options = {}) 
  now=Time.now
  start_time=start_time 
  end_time = start_time + 7.days + 1.hours
  
  events_hash = [] 
  with_scope(:find => options) do 
   
    events_hash = self.find(:all,:conditions => [ 'event_on BETWEEN ? AND ?',start_time.to_date,end_time.to_date],:order => 'start_time,events_events.map_location_id, events_events.event_on,events_events.name', :include => [ :map_location, :events_instructor, :icon_file ] ).find_all { |evt| now < evt.event_starts_at  }.group_by do |evt|
                  evt.event_on.strftime("%w")
                end
  end
  days_list = (0..6).to_a
  event_arr = []
  start_day = end_time.at_beginning_of_week - 1.days
  days_list.each do |day|
  cur_time = start_day + day.days
  
  last_parent = nil
  last_start_time = nil
  day_arr = []
  (events_hash[day.to_s]||[]).each do |evt|
      cur_parent = evt.parent_event_id.blank? ? evt.id : evt.parent_event_id
      
      if cur_parent != last_parent || last_start_time != evt.start_time
        day_arr << evt
      end
      last_parent = cur_parent
      last_start_time = evt.start_time
      
    end
    
    
    event_arr << { :time => cur_time, :events => day_arr || [] }
  end
  
  event_arr 
 end
 
 def event_date
  self.event_on.to_time
 end

 # Show a full event calendar
 def self.full_event_calendar(start_at,end_at)
    event_list = EventsEvent.find(:all,:conditions => [ 'event_on BETWEEN ? AND ?',start_at.to_date,end_at.to_date ])
                                                
    days = self.generate_visible_days(start_at,end_at)
    event_arr = event_list.group_by(&:event_date)
    
    days[:days].map! do |week|
      week.map! do |day|
        { :date => day[:date],
          :events => event_arr[day[:date]] ? event_arr[day[:date]].sort { |a,b| a.start_time <=> b.start_time }.map { |elm| [ elm, elm.target ] } : []
        }
      end
    end
    
    days                                                
 end
 
 # Show a list of Targeted events
 def self.event_calendar(start_at,end_at,target_list,show_private = true)
    
    days = self.generate_visible_days(start_at,end_at)
    
    target_hash = target_list.group_by { |elm| elm.class.to_s }
    target_item_hash = {}
    target_id_list = {}
    target_hash.each do |clss,elm|
      target_item_hash[clss] ||= {}
      target_id_list[clss] ||= []
      elm.each do |itm|
        target_id_list[clss] << itm.id
        target_item_hash[clss][itm.id] = itm
      end
    end
    
    
    event_list = []
    target_id_list.each do |clss,id_list|
      if show_private
        event_list += EventsEvent.find(:all,:conditions => [ 'event_on BETWEEN ? AND ? AND target_type=? AND target_id IN (?)',
                                                start_at.to_date,end_at.to_date,clss,id_list ])
      else
        event_list += EventsEvent.find(:all,:conditions => [ 'event_on BETWEEN ? AND ? AND target_type=? AND target_id IN (?) AND is_private = 0 ',
                                                start_at.to_date,end_at.to_date,clss,id_list ])
      end
    end
    
    event_arr = event_list.group_by(&:event_date)
    
    days[:days].map! do |week|
      week.map! do |day|
        { :date => day[:date],
          :events => event_arr[day[:date]] ? event_arr[day[:date]].sort { |a,b| a.start_time <=> b.start_time }.map { |elm| [ elm, target_item_hash[elm.target_type][elm.target_id] ] } : []
        }
      end
    end
    
    days
 end
 
 def self.generate_visible_days(start_date,end_date)
  
    # get the day of the week
    dow = start_date.wday
    
    # get the sunday prior to the start of the month
    calendar_start = start_date - dow.days
    
    eom = end_date
    
    calendar_end = (eom + (6-eom.wday).days).midnight
    
    # return start / end and a two dimensional array of [week][day of week] (0 indexed)
    output = { :start => calendar_start, :end => calendar_end, :days => [] }
    
    date = calendar_start
    day = 0
    week = 0
    while date <= calendar_end do
      output[:days][week] ||= []
      output[:days][week] << { :date => date.clone }
      day+=1
      week += 1 if day % 7 == 0
      date = (date.tomorrow + 2.hours).at_beginning_of_day
    end
    
    output
  end 
  
 
 def available?
  self.unconfirmed_bookings < self.event_spaces
 end
 
 def book_user!(user,options = {})
  credits = EventsUserCredit.get_credits(user,self.events_credit_type_id) 
  
  if(credits > 0 || options[:no_credit])
    self.reload(:lock => true)
    self.update_unconfirmed!(:booking_check => true)
    begin
      raise "No Space" if self.unconfirmed_bookings >= self.event_spaces
      raise "Existing Booking" if self.events_bookings.find_by_end_user_id(user.id,:conditions => 'confirmed = "1"' )
      raise "No Credits" unless options[:no_credit] || EventsUserCredit.use_credit!(user,self.events_credit_type_id, :admin_user_id => options[:admin_user_id], :description => self.short_description) 
      booking = self.events_bookings.create(:end_user_id => user.id, :confirmed => true)
      self.update_attributes(:event_bookings => self.event_bookings + 1,
                             :unconfirmed_bookings => self.unconfirmed_bookings + 1)
      return nil
    rescue Exception => e
      self.save # Clear the lock
      return e.to_s
    end
  else
    return "No Credits"
  end
 end
 
 def book_user_unconfirmed!(user,options = {})
  self.reload(:lock => true)
  self.update_unconfirmed!(:booking_check => true)
  begin
    raise "No Space" if self.unconfirmed_bookings >= self.event_spaces
    raise "Existing Booking" if self.events_bookings.find_by_end_user_id(user.id,:conditions => 'confirmed = 1' )
    now = Time.now
    valid_until_time = (now +(options[:hold_time]||5).minutes)
    booking = self.events_bookings.find(:first,:conditions => [ 'end_user_id=? AND confirmed = 0 AND valid_until > ?',user.id,now])
    if !booking
      booking = self.events_bookings.create(:end_user_id => user.id, :confirmed => false,:valid_until => valid_until_time)
      self.update_attributes(:unconfirmed_bookings => self.unconfirmed_bookings + 1)
    else
      booking.update_attribute(:valid_until,valid_until_time)
      self.save
    end
    return booking
  rescue Exception => e
    self.save # Clear the lock
    return nil
  end
  return nil
 end
 
 def confirm_booking!(booking)
  self.reload(:lock => true)
  booking.update_attributes(:confirmed => true, :valid_until => false)
  self.update_unconfirmed!(:booking_check => true)
  self.update_attributes(:event_bookings => self.event_bookings + 1)
 end
 
 def cancel_booking!(booking)
  begin
    self.reload(:lock => true)
    self.update_unconfirmed!(:booking_check => true)
    self.update_attributes(:event_bookings => self.event_bookings - 1)
  rescue Exception => e
    return
  end
 end 
 
 # Update the number of unconfirmed bookings
 # options[:force] - forces a update 
 # options[:booking_check] (internal) - recalcs unconfirmed bookings during book_user! 
 def update_unconfirmed!(options = {})
  now = Time.now
  if(!self.last_unconfirmed_check || self.last_unconfirmed_check < now - 5.minutes || options[:force]) 
    self.reload(:lock => true) unless options[:booking_check]
    self.attributes =  { :last_unconfirmed_check => now,
                           :unconfirmed_bookings => self.events_bookings.count(:all,
                                :conditions => ['confirmed = 1 OR (confirmed = 0 AND valid_until > ?)',now ]) }
    self.save unless options[:booking_check]
                          
  end
 end
 
 def upcoming_siblings
  return @upcoming_siblings if @upcoming_siblings
  match_id =self.parent_event_id.blank? ?  self.id : self.parent_event_id
  @upcoming_siblings = EventsEvent.find(:all,:conditions => ['(events_events.id = ? OR parent_event_id = ?) AND event_on >= CURDATE()', match_id,match_id],:order => 'event_on,start_time')
 end
 
 
  def self.get_content_description 
    "Event".t 
  end

  def self.get_content_options
    self.find(:all,:order => 'name',:conditions => 'parent_event_id IS NULL').collect do |item|
      [ item.name,item.id]
    end
  end

  def title
    self.name
  end

  def self.comment_posted(blog_id)
  end 
  
  def self.map_data(events)
  
    bounds = { :lat_min => 1000, :lat_max => -1000, :lon_min => 1000, :lon_max => -1000 }
    data = events.collect do |evt|
      if evt.lat && evt.lon
          bounds[:lat_min] = evt.lat if evt.lat < bounds[:lat_min]
          bounds[:lat_max] = evt.lat if evt.lat > bounds[:lat_max]
          bounds[:lon_min] = evt.lon if evt.lon < bounds[:lon_min]
          bounds[:lon_max] = evt.lon if evt.lon > bounds[:lon_max]
          { :lat => evt.lat,
            :lon => evt.lon,
            :title => evt.name,
            :ident => evt.id
          }
      else
        nil
      end
    end.compact
    center = data.length > 0 ? [  data[0][:lat], data[0][:lon] ] : nil
    
    { :zoom => 11,  :center => center, :click => true, :markers => data }
  end
  
 
end
