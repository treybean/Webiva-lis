
class Calendar::ManageController < ModuleController
  
  permit 'calendar_manage'

  component_info 'Calendar'

  # need to include 
  
  def self.members_view_handler_info
    { 
      :name => 'Appointments',
      :controller => '/calendar/manage',
      :action => 'booking_credits'
    }
   end  
  
  def display_calendar(display=true)
    
    current_date = Time.now
        
    if params[:date]
      @visible_month = params[:date].split("-")[1]
      @visible_year = params[:date].split("-")[0]
    else
      @visible_month = params[:month] || current_date.month
      @visible_year = params[:year] || current_date.year
    end
    
    @visible_date = Time.local(@visible_year,@visible_month,1)
    
    if params[:view]
      case params[:view]
        when 'previous_month': 
          @visible_date = @visible_date.last_month
        when 'next_month': 
          @visible_date = @visible_date.next_month
      end
      @visible_month = @visible_date.month
      @visible_year = @visible_date.year
    end
    now = Time.now.strftime("%Y-%m-%d")
    content_target = now + @visible_month.to_s + "-" + @visible_year.to_s
    
    #@blocks = DataCache.get_content('Calendar','Admin',content_target) if false
    #if !@blocks 
      # Get the visible days of the catalog
      @days = Calendar::Utility.generate_visible_days(@visible_month,@visible_year)
      
      # Get all the availabilities, bookings and holidays
      @calendar = Calendar::Utility.generate_calendar(@days)
      
      # Turn into blocks
      @blocks = Calendar::Utility.generate_blocks(@calendar)
      
      @blocks = Calendar::Utility.format_block(@blocks,110,90)
      
      #DataCache.put_content('Calendar','Admin',content_target,@blocks)
    #end
    
    @slot_ids = CalendarSlot.find(:all,:order => 'name').map(&:id)
    require_css('/components/calendar/stylesheets/manage_calendar.css')
    render :partial => 'calendar' if display
  end
  
  def index
   cms_page_info [ ["Content",url_for(:controller => '/content') ], "Appointments" ], "content"
  
   display_calendar(false)
  
  end
  
  def show_day
    
  
    @date = Time.parse(params[:date])
    
    if params[:cancel_booking_id]
      @cancel_booking = CalendarBooking.find_by_id(params[:cancel_booking_id])
      if @cancel_booking
          @cancel_booking.destroy
          CalendarUser.update_credits(@cancel_booking.end_user,1,"Admin Canceled:" + @cancel_booking.time_description, :admin_user_id => myself.id) if @cancel_booking.end_user && @cancel_booking.confirmed?
      end
    end
    
    opts = Calendar::Utility.options
    
    @days = Calendar::Utility.generate_day(@date)
    # Get all the availabilities, bookings and holidays
    @calendar = Calendar::Utility.generate_calendar(@days)
    @blocks = Calendar::Utility.generate_blocks(@calendar)
      
    @area_width = 800
    @area_height = 450
    
    #@blocks = Calendar::Utility.format_block(@blocks,@area_width,@area_height)    
    @day = @blocks[0][0]
    
    @date_link = @date.strftime("%Y-%m-%d")
    
    

    @spaces = Calendar::Utility.signup_blocks(@day, :block_minutes => opts.block_minutes,
                                                              :signup_length => opts.signup_minutes,
                                                              :start_time => opts.start_time,
                                                              :end_time => opts.end_time )
    
    @all_slot_ids = @spaces[:slots].keys
    @slot_ids = CalendarSlot.find(:all,:order => 'name').map(&:id).select { |slt| @all_slot_ids.include?(slt) }

    @block_width = (@area_width - 140) / (@slot_ids.length > 0 ? @slot_ids.length : 1 )
    @block_width = 120 if @block_width > 120
    @block_height = @area_height / (@spaces[:blocks].length+1)
    @block_height = 14 if @block_height < 14
    
    render :partial => 'day' 
  end
  
  def edit_booking
    
    @area_width = 800
    @area_height = 450
    
    @booking = CalendarBooking.find_by_id(params[:path][0]) || CalendarBooking.new( :admin_user_id => myself.id)

    @show_day_on_cancel = (params[:show_day_on_cancel] || params[:date] || @booking.id) ? true : false

    if !params[:booking]  && !@booking.id
      @booking.booking_on = params[:date] ? Time.parse(params[:date]) : Time.now.at_midnight
      @booking.start_time = params[:start_time]
      @booking.end_time = params[:end_time]
      @availability = CalendarAvailability.find_by_id(params[:availability])
      @booking.verify_availability = ['verify']
      @booking.calendar_slot_id = @availability.calendar_slot_id if @availability
      @booking.apply_credits = 'verify'
    end
    
    @slots = CalendarSlot.find_select_options(:all,:order => 'name')
    if !@booking.id
      @slots = CalendarSlotGroup.find(:all,:order => 'calendar_slot_groups.name',:include => :calendar_slots).collect { |sg|
            [ " #{sg.name} Group (#{sg.calendar_slots.length})", "Group#{sg.id}" ]
          } + [[ '---','']] + @slots
    end
    
    if request.post? && params[:booking]
      @booking.confirmed = true
      @booking.attributes = params[:booking]
      @booking.admin_user_id = myself.id
      if @booking.valid?
        @booking.save
        render :update do |page|
          page << "CalEditor.close(); CalEditor.updateCalendar({ year: #{@booking.booking_on.strftime("%Y")},month: #{@booking.booking_on.strftime("%m")}});"
        end
        return
      end
    end    
    
    render :partial => 'edit_booking'
  end
  
  def view_booking
    @booking = CalendarBooking.find_by_id(params[:path][0]) unless @booking
    
    
    render :partial => 'view_booking'
  end
  
  helper 'calendar/manage'
  
 
  include ActiveTable::Controller 
  
  active_table :calendar_user_credits_table,
                CalendarUserCredit,
                [ 
                  ActiveTable::NumberHeader.new('credit_difference',:label => 'Crd.'),
                  ActiveTable::StringHeader.new('calendar_user_credits.description',:label => 'Desc.'),
                  ActiveTable::DateRangeHeader.new('calendar_user_credits.created_at',:datetime => true, :label => 'Adjustment Date'),
                  ActiveTable::NumberHeader.new('calendar_user_credits.shop_order_id',:label => 'Order #'),
                  ActiveTable::StaticHeader.new('Admin User')
                ]
                
  
  def display_calendar_user_credits_table(display = true)
    @user = EndUser.find_by_id(params[:path][0]) unless @user
    
    @tbl = calendar_user_credits_table_generate params, :order => 'calendar_user_credits.created_at DESC',
                 :conditions => ['(end_user_id = ?)',@user.id]
    
    render :partial => 'calendar_user_credits_table' if display
  end
  
  active_table :user_booking_table,
                CalendarBooking,
                [ 
                  ActiveTable::DateRangeHeader.new('calendar_bookings.booking_on',:datetime => true, :label => 'Booking Date'),
                  ActiveTable::OrderHeader.new('calendar_bookings.start_time',:label => 'Time'),
                  ActiveTable::OrderHeader.new('calendar_bookings.calendar_slot_id',:label => 'With')
                ]
                  
  
  def display_user_booking_table(display=true)
    @user = EndUser.find_by_id(params[:path][0]) unless @user
    
    @booking_tbl = user_booking_table_generate params, :order => 'calendar_bookings.booking_on DESC',:include => :calendar_slot,
                 :conditions => ['(end_user_id = ?) AND (confirmed=1 OR valid_until > NOW())',@user.id]
    
    render :partial => 'calendar_user_booking_table' if display
  end
  
  def booking_credits
    @tab = params[:tab]
    
    if request.post? && params[:credit]
      @user = EndUser.find_by_id(params[:path][0])
      CalendarUser.update_credits(@user,params[:credit][:credit_difference].to_i,params[:credit][:description],:admin_user_id => myself.id)
    end 
  
    display_calendar_user_credits_table(false)
    display_user_booking_table(false)
    
    @calendar_user = CalendarUser.user(@user)
    render :partial => 'booking_credits'
  end
  
  
  def edit_holiday
    @area_width = 650
    @area_height = 400
    
    @holiday = CalendarHoliday.find_by_id(params[:path][0]) || CalendarHoliday.new()  
    
    if !params[:holiday] && !@holiday.id
      @holiday.start_on = params[:date] ? Time.parse(params[:date]) : Time.now.at_midnight
      @holiday.end_on = params[:date] ? Time.parse(params[:date]) : Time.now.at_midnight
      @holiday.start_time = 0.0
      @holiday.end_time = 1425.0
    end
    
    if request.post? && params[:holiday]
      if @holiday.update_attributes(params[:holiday])
        render :update do |page|
          page << "CalEditor.close(); CalEditor.updateCalendar({ year: #{@holiday.start_on.strftime("%Y")},month: #{@holiday.start_on.strftime("%m")}});"
        end
        return
      end
    end
    
    
    render :partial => 'edit_holiday'    
  end
  
  def clear_holiday
    @holiday = CalendarHoliday.find_by_id(params[:cancel_holiday_id])
    
    @holiday.destroy if @holiday
    
    render :nothing => true
  end


end
