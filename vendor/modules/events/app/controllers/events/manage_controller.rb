

class Events::ManageController < ModuleController

#  permit 'events_manage'
  
  component_info 'Events'
  
  
  
  cms_admin_paths 'content',
                  "Content" => { :controller => '/content' },
                  "Configure" => { :action => 'configure' }  
                  
  before_filter :get_opts

  include Events::TimeHelper
  
  helper_method :time_display

  def get_opts
      @opts = Events::AdminController.module_options
  end
  
  def index
      cms_page_path [ 'Content'],[ "%s", nil, @opts.events_name ]
      session[:event_calendar_offset] = @offset = (params[:offset] || session[:event_calendar_offset]).to_i
  
      @start_of_week = Time.now.at_beginning_of_week
      @start_of_week += (7 * @offset).days
      @week_days, @week_events = EventsEvent.week_schedule(@start_of_week) 
  end
  
  def event_calendar 
    session[:event_calendar_offset] = @offset = (params[:offset] || session[:event_calendar_offset]).to_i
    @start_of_week = Time.now.at_beginning_of_week
    @start_of_week += (7 * @offset).days
    @week_days, @week_events = EventsEvent.week_schedule(@start_of_week) 
    render :partial => 'event_calendar'
  end
  
  def view
      @event = EventsEvent.find(params[:path][0])
      cms_page_path [ 'Content', [ "%s", url_for(:action => 'index'), @opts.events_name ]],["%s",nil,@event.name]
  
  end
  
  def cancel
     @event = EventsEvent.find_by_id(params[:path][0])
     
     if @event
       @event.child_events.each { |evt| evt.destroy } if params[:destroy]
       @event.destroy
       flash[:notice] = "Deleted " + @opts.event_name
       redirect_to :action => 'index'
     end
     expire_content
  end
  
  def edit
      @event = EventsEvent.find_by_id(params[:path][0]) || EventsEvent.new(:duration => 60, :start_time => 6 * 60,:days_advance => 90)
      @new_event = !@event.id

      cms_page_path [ 'Content', [ "%s", url_for(:action => 'index'), @opts.events_name ]],
                      @event.id ? ["Edit %s",nil,@event.name] : ["Add a new %s",nil,@opts.event_name]
        
      if request.post? && params[:event]
        expire_content
        @event.attributes = params[:event]
        if params[:update_parent_repeating].to_s == '1'
          @event.take_over_repeating!
        end
        
        @event.parent_event_id = nil
        @event.events_repeat_id = nil
        if(@event.save)
          expire_content    
          flash[:notice] = @new_event ? "Created new event".t : "Edited %s" / @event.name
          redirect_to :action => 'index'
        end
      end
      
      @repeat = EventsRepeat.new(:start_time => 6 * 60)
      @instructors = EventsInstructor.find_select_options(:all,:order => 'name')      
      @locations = MapLocation.find_select_options(:all)
      require_js('cms_form_editor.js')
      
  end
  
  def event_booking
    @event = EventsEvent.find(params[:event_id])
    
    if params[:cancel_booking_id]
      booking = @event.events_bookings.find_by_id(params[:cancel_booking_id])
      if booking && booking.events_event.event_starts_at > Time.now && booking.destroy
        EventsUserCredit.credit_adjustment!(booking.end_user,@event.events_credit_type_id,1,"Admin Cancel: #{booking.name} #{booking.get_description}",:admin_user_id => myself.id)
        @result = 'been removed from the ' + @opts.events_name.to_s.singularize.downcase
        @cancel = 1
        @member = booking.end_user
        
        @event.reload
        
      end
      expire_content    
    end
    
    render :partial => 'class_registration_overlay'
  end
  
  def add_member
    if params[:end_user_id]
      @member = EndUser.find_by_id(params[:end_user_id])
    elsif !params[:member_id].blank?
      @member = EndUser.find_by_membership_id(params[:member_id])
    end
      
    @event = EventsEvent.find(params[:path][0]) 
    if @member
      @result = @event.book_user!(@member,:no_credit => params[:no_credit].to_s == '1', :admin_user_id => myself.id) 
    else 
      @result = 'Invalid User'
    end
    
    expire_content    
    render :partial => 'class_registration'
  end
  
  def remove_member 
      
    @event = EventsEvent.find(params[:path][0]) 
    booking = @event.events_bookings.find_by_id(params[:cancel_booking_id]) if @event
    if booking && booking.destroy
        EventsUserCredit.credit_adjustment!(booking.end_user,@event.events_credit_type_id,1,"Admin Cancel: #{booking.name} #{booking.get_description}",:admin_user_id => myself.id)
        @result = 'been removed from the ' + @opts.events_name.to_s.singularize.downcase
        @cancel = 1
        @member = booking.end_user
        @event.reload
    end
    
    expire_content    
    render :partial => 'class_registration'
  end
  
  def add_repeat
    @event = EventsEvent.find_by_id(params[:path][0]) || EventsEvent.new()
    
    @locations = MapLocation.find_select_options(:all)
    @instructors = EventsInstructor.find_select_options(:all,:order => 'name')
    
    if params[:parent]
      @repeat = @event.parent_repeat
    else
      @repeat = @event.events_repeats.build(:start_on => params[:start_on],
                                         :start_time => params[:start_time],
                                         :repeat_type => params[:repeat_type],
                                         :events_instructor_id => params[:events_instructor_id],
                                         :map_location_id => params[:map_location_id] )
    
    end
    render :partial => 'repeat', :locals => {:repeat => @repeat, :idx => params[:idx] }
  end
  
  include ActiveTable::Controller
  
  active_table :credit_types, EventsCreditType, [ ActiveTable::IconHeader.new('',:width => 10),
                                                  ActiveTable::StringHeader.new('name') ]
  
  def display_credit_types_table(display=true)
    active_table_action('credit_type') do |act,cids|
      EventsCreditType.destroy(cids) if act=='delete'
    end
    
    @tbl = credit_types_generate params,:order => 'name'
    
    render :partial => 'credit_types_table' if display
  
  end
  
  def configure
    cms_page_path [ 'Content', [ "%s", url_for(:action => 'index'), @opts.events_name ]], "Configure"
  
    display_credit_types_table(false)
  end
  
  def credit_type
    cms_page_path [ 'Content', [ "%s", url_for(:action => 'index'), @opts.events_name ], "Configure"],"Credit Type"
    
    @credit_type = EventsCreditType.find_by_id(params[:path][0]) || EventsCreditType.new()
    
    if request.post? && params[:credit_type] && @credit_type.update_attributes(params[:credit_type])
      expire_content
      redirect_to :action => 'configure'
    end
  end
  
  def attendance
    cms_page_path [ 'Content' ], "Attendance"
    
  
  end
  
  protected
  
  def expire_content
      DataCache.expire_content("Events")
  end
end

