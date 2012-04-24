class Events::AdminController < ModuleController
  permit 'event_admin'

  # Dependant on the Map Module
  # register_dependency :map
  
  component_info 'Events', :description => 'Events Component', 
                              :access => :private
                              
  register_permission_category :events, "Event" ,"Permissions for Event Actions"
  
  register_permissions :events, [  [ :manage, 'Event Manage', 'Manage Events' ],
                                 [ :admin, 'Event Admin', 'Event Configuration']
                             ]

  content_model :events
  
  register_handler :shop, :product_feature, "Events::BookingCreditPack"
  register_handler :shop, :product_feature, "Events::ProductBooking"
  
  register_cron :generate_events, "Events::Cron", :hours => [ 3 ]
  
  register_handler :members, :view,  "Events::UserController"
  
  cms_admin_paths "options",
                   "Options" =>   { :controller => '/options' },
                   "Modules" =>  { :controller => '/modules' },
                   "Event Options" => { :action => 'index' }

  register_handler :model, :end_user, "Events::EndUserExtension", :actions => [ :after_create  ] 

  protected
 def self.get_events_info
  info  = self.module_options
      [
      {:name => info.events_name,:url => { :controller => '/events/manage' } ,:permission => 'events_manage', :icon => 'icons/content/calendar.gif' },
      {:name => "Check-in",:url => { :controller => '/events/attendance' } ,:permission => 'events_manage', :icon => 'icons/content/calendar.gif' }
      
      ]
  end

 public 
 def options
    cms_page_path ['Options','Modules'],'Event Options'
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && params[:options] && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated event module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
    default_options :event_name => 'Event', :events_name => 'Events', :instructor_name => 'Instructor', :subtitle_name => 'Room', :automatic_credit => 0, :instructor_cost => 5
  
    integer_options :automatic_credit
  end
  
end
