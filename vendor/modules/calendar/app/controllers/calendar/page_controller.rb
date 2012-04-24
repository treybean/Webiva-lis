require 'icalendar'

class Calendar::PageController  < ParagraphController


  user_actions :ical

  editor_header "Calendar Paragraphs"
  editor_for :month_schedule, :name => 'Multi-Day Schedule Display',  :features => ['calendar_month_schedule'],
                    :inputs => [ [ :page_date, 'Display Date', :path ] ]
                    
  editor_for :day_schedule, :name => 'Single Day Schedule Display',  :features => ['calendar_day_schedule'],
                    :inputs => [ [ :page_date, 'Display Date', :path ] ]


  editor_for :booking, :name => 'Session Booking Display', :features => ['calendar_booking']
  
  editor_for :user_bookings, :name => 'User\'s Bookings Display', :features => ['calendar_user_bookings']
                    

  def month_schedule

    @options = MonthScheduleOptions.new(params[:month_schedule] || @paragraph.data)
      
    return if handle_module_paragraph_update(@options)
    
    @days = [[ '--Select a detail page--',nil]] +  SiteNode.page_options()

    @slots = [[ '--Select Slot--','']] + CalendarSlotGroup.find(:all,:order => 'calendar_slot_groups.name',:include => :calendar_slots).collect { |sg|
      [ " #{sg.name} Group (#{sg.calendar_slots.length})", "Group#{sg.id}" ]
    } + [[ '---','']] + CalendarSlot.find_select_options(:all,:order => 'name').collect { |elm| [elm[0],elm[1].to_s] }
 
  end

  class MonthScheduleOptions < HashModel
      default_options  :display => 'group', :block_width => 70, :block_height => 70, :day_page_id => nil, :slot_id => nil
      
      integer_options :block_width, :block_height, :day_page_id
      
      validates_presence_of :block_width, :block_height, :display
  end
  
  def day_schedule
    @options = DayScheduleOptions.new(params[:day_schedule] || @paragraph.data)
    
    return if handle_module_paragraph_update(@options)
    
    @pages = [[ '--Booking page--',nil]] +  SiteNode.page_options()

    @slots = [[ '--Select Slot--','']] + CalendarSlotGroup.find(:all,:order => 'calendar_slot_groups.name',:include => :calendar_slots).collect { |sg|
      [ " #{sg.name} Group (#{sg.calendar_slots.length})", "Group#{sg.id}" ]
    } + [[ '---','']] + CalendarSlot.find_select_options(:all,:order => 'name').collect { |elm| [elm[0],elm[1].to_s] }
 
  end
  
 class DayScheduleOptions < HashModel
  default_options :display => 'group', :block_minutes => 60, :signup_length => 60, :block_width => 70, :block_height => 20, :booking_page_id => nil, :slot_id => nil
  
  integer_options :block_minutes, :block_width, :block_height, :signup_length, :booking_page_id 
  
  validates_presence_of :display, :block_minutes, :block_width, :block_height, :signup_length
      
 end
 
 def booking
  @options = BookingOptions.new(params[:booking] || @paragraph.data)
  
  return if handle_module_paragraph_update(@options)
  
  @products = Shop::ShopProduct.select_options
  
  @pages = SiteNode.page_options()
  @slots = [[ '--Select Slot--','']] + CalendarSlotGroup.find(:all,:order => 'calendar_slot_groups.name',:include => :calendar_slots).collect { |sg|
      [ " #{sg.name} Group (#{sg.calendar_slots.length})", "Group#{sg.id}" ]
    } + [[ '---','']] + CalendarSlot.find_select_options(:all,:order => 'name').collect { |elm| [elm[0],elm[1].to_s] }
 
 end
 
 class BookingOptions < HashModel
  default_options :booking_minutes => 60, :minutes_hold_time => 15, :maximum_unconfirmed_sessions => 10, :slot_id => nil, :calendar_page_id => nil, :checkout_page_id => nil, :booking_credit_product_id => nil,:auto_book => false, :auto_book_page_id => nil
  
  boolean_options :auto_book
  
  integer_options :booking_minutes, :minutes_hold_time, :maximum_unconfirmed_sessions, :calendar_page_id, :checkout_page_id, :booking_credit_product_id, :auto_book_page_id
  
  validates_presence_of :slot_id, :booking_minutes, :minutes_hold_time, :maximum_unconfirmed_sessions
 end


  def user_bookings
    @options = UserBookingsOptions.new(params[:user_bookings] || @paragraph.data)
    
    return if handle_module_paragraph_update(@options)
  end
  
  class UserBookingsOptions < HashModel
    default_options :cancellation_hours => 24, :allow_cancellations => 'yes'
    
    integer_options :cancellation_hours
    
  end
  
  
  def ical
    cal = Icalendar::Calendar.new
    
    slot = CalendarSlot.find_by_slot_hash(params[:path][0],:conditions => 'slot_hash IS NOT NULL')
    
    if !slot
      render :text => 'Invalid Calendar'
      return
    end
    
    bookings = CalendarBooking.find(:all,:conditions => ['booking_on > ? AND confirmed=1 AND calendar_slot_id=?',Time.now.yesterday.at_midnight,slot.id],:order => 'booking_on,start_time')
    
    bookings.each do |booking|
      event = Icalendar::Event.new
      event.start = booking.to_time.strftime("%Y%m%dT%H%M%S")
      event.end = booking.to_end_time.strftime("%Y%m%dT%H%M%S")
      event.summary = booking.recipient_name + " " + booking.time
      cal.add_event(event)
    end
    
    send_data(cal.to_ical,:type => 'text/calendar', :disposition => 'inline; filename=calendar.cvs', :filename => 'calendar.vcs')
  end

end
