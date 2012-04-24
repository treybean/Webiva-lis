
class Events::UserController < ModuleController
  
  permit 'events_manage'

  component_info 'Events'

  # need to include 
  
 before_filter :get_opts

  include Events::TimeHelper
  
  helper_method :time_display

  def get_opts
      @opts = Events::AdminController.module_options
  end  
  
  def self.members_view_handler_info
    opts = Events::AdminController.module_options
    { 
      :name => opts.event_name.pluralize,
      :controller => '/events/user',
      :action => 'view'
    }
   end  
  
 include ActiveTable::Controller 
  
  active_table :user_credits_table,
                EventsUserCreditEntry,
                [ 
                  ActiveTable::NumberHeader.new('credit_difference',:label => 'Crd.'),
                  ActiveTable::StringHeader.new('events_user_credit_entries.description',:label => 'Description'),
                  ActiveTable::DateRangeHeader.new('events_user_credit_entries.created_at',:datetime => true, :label => 'Adjustment Date'),
                  ActiveTable::NumberHeader.new('events_user_credit_entries.shop_order_id',:label => 'Order #'),
                  ActiveTable::StaticHeader.new('Admin User')
                ]
                
  
  def display_user_credits_table(display = true)
    @user = EndUser.find_by_id(params[:path][0]) unless @user
    
    @tbl = user_credits_table_generate params, :order => 'events_user_credit_entries.created_at DESC',
                 :conditions => ['(end_user_id = ?)',@user.id], :joins => :events_credit_type
    
    render :partial => 'user_credits_table' if display
  end
  
  active_table :user_booking_table,
                EventsBooking,
                [ ActiveTable::IconHeader.new('',:width => 10),
                  ActiveTable::StringHeader.new('events_events.name',:label => 'Name'),
                  ActiveTable::DateRangeHeader.new('events_events.event_on',:datetime => true, :label => 'Date'),
                  ActiveTable::OrderHeader.new('events_events.start_time',:label => 'Time'),
                ]
                  
  
  def display_user_booking_table(display=true)
    @user = EndUser.find_by_id(params[:path][0]) unless @user
    @tab = params[:tab]
    
    active_table_action('user_class') do |action,cids|
      if action=='cancel'
        cids.each do |booking_id|
          booking = EventsBooking.find_by_end_user_id_and_id(@user.id,booking_id)
          if booking.events_event.event_starts_at > Time.now && booking.destroy
              EventsUserCredit.credit_adjustment!(@user,booking.events_event.events_credit_type_id,1,"Admin Cancel: #{booking.name} #{booking.get_description}",:admin_user_id => myself.id)
          end
        end
        @refresh_all = true
      end
    end
    
    
    @booking_tbl = user_booking_table_generate params, :order => 'events_events.event_on DESC',:joins => :events_event,
                 :conditions => ['(end_user_id = ? AND confirmed=1)',@user.id]
    
    
    render :partial => 'user_booking_table' if display
  end
  
  def view
    @tab = params[:tab]
    
    if request.post? && params[:credit]
      @user = EndUser.find_by_id(params[:path][0])
      EventsUserCredit.credit_adjustment!(@user,params[:credit][:events_credit_type_id],params[:credit][:credit_difference].to_i,params[:credit][:description],:admin_user_id => myself.id)
    end 
  
    display_user_credits_table(false)
    display_user_booking_table(false)
    
    @user_credits = EventsUserCredit.find(:all,:conditions => ['end_user_id=?',@user.id])
    
    #@calendar_user = CalendarUser.user(@user)
    render :partial => 'view'
  end   
  
  
end
