

class Events::InstructorController <  ModuleController

  permit 'events_manage'
  
  component_info 'Events'
  
  cms_admin_paths 'content',
                  "Content" => { :controller => '/content' },
                  "Events" => { :controller => '/events/manage' }
                  

  before_filter :get_opts

  include Events::TimeHelper
  
  helper_method :time_display

  def get_opts
      @opts = Events::AdminController.module_options
  end
  
 include ActiveTable::Controller
  
  active_table :instructors_table, EventsInstructor, [ ActiveTable::IconHeader.new('',:width => 10),
                                                  ActiveTable::StaticHeader.new(' '),
                                                  ActiveTable::StringHeader.new('name'),
                                                  ActiveTable::StringHeader.new('description') ]
  
  def display_instructors_table(display=true)
    active_table_action('instructor') do |act,iids|
      EventsInstructor.destroy(iids) if act=='delete'
    end
    
    @tbl = instructors_table_generate params,:order => 'name'
    
    render :partial => 'instructors_table' if display
  end
  
  def index
    cms_page_path [ 'Content',[@opts.events_name,url_for(:controller => '/events/manage')]],@opts.instructor_name
    display_instructors_table(false)  
  
  end
  
  def edit
    @instructor = EventsInstructor.find_by_id(params[:path][0]) || EventsInstructor.new()

    cms_page_path [ 'Content','Events',["%s",url_for(:action => 'index'), @opts.instructor_name.pluralize]],
        @instructor.id ? "Edit %s" / @opts.instructor_name : "Create %s" / @opts.instructor_name
    
    if request.post? && params[:instructor] && @instructor.update_attributes(params[:instructor]) 
      flash[:notice] = "Update %s" / @instructor.name
      redirect_to :action => 'index'
      expire_content
    end
  
    require_js('cms_form_editor')
  end
  
  def tracking
    cms_page_path [ 'Content',
                  [@opts.events_name,url_for(:controller => '/events/manage')],
                  [@opts.instructor_name.pluralize,url_for(:action => 'index')],
                  ], @opts.instructor_name + " Tracking"

    @opts = TrackingModel.new(params[:tracking] || session[:instructor_tracking])
    
    session[:instructor_tracking] = @opts.to_hash
    
    @opts.start_date = @opts.start_date ? Time.parse(@opts.start_date) : (Time.now.at_beginning_of_week - 2.weeks)
    @opts.end_date = @opts.end_date ? Time.parse(@opts.end_date) :  (Time.now.at_beginning_of_week - 1.days)
    
    mod_opts = Events::AdminController.module_options
    
    @total_cnt =  EventsBooking.count(:all,:conditions => ['confirmed=1 AND events_events.event_on >= ? AND events_events.event_on <=  ?',@opts.start_date.at_midnight,@opts.end_date.at_midnight + 1 .days], :joins => [ :events_event ] )
    
    @instructors = EventsInstructor.find(:all,:order => 'name')
    @tbl = @instructors.collect do |instructor|
        cnt = EventsBooking.count(:all,:conditions => ['confirmed=1 AND events_events.events_instructor_id=? AND events_events.event_on >= ? AND events_events.event_on <=  ?',instructor.id,@opts.start_date.at_midnight,@opts.end_date.at_midnight + 1 .days], :joins => [ :events_event ] )
        [ instructor, cnt, cnt.to_f * mod_opts.instructor_cost]
      
    end
    
  end
  
  class TrackingModel < HashModel
    default_options :start_date => nil, :end_date => nil
  end
  
  protected
  
  def expire_content
      DataCache.expire_content("Events")
  end
  
  
end
