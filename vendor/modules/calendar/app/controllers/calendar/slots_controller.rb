
class Calendar::SlotsController < ModuleController
  
  permit 'calendar_manage'

  component_info 'Calendar'

  cms_admin_paths "content",
                   "Content" =>   { :controller => '/content' },
                   "Appointments" =>  { :controller => '/calendar/manage' },
                   "Calendar" =>  { :controller => '/calendar/manage' },
                   "Configure Calendar" => { :action => 'index' },
                   "Configure" => { :action => 'index' },
                   "Slot Groups" => { :action => 'groups' }

  include ActiveTable::Controller
  active_table :slots_table,
                CalendarSlot,
                [ ActiveTable::IconHeader.new('', :width=>10),
                  ActiveTable::StringHeader.new('calendar_slots.name',:label => 'Name'),
                  ActiveTable::StringHeader.new('calendar_slot_group.name',:label => 'Group'),
                  ActiveTable::StaticHeader.new('Availabilities'),
                  ActiveTable::StaticHeader.new('iCal')

                ]
              
  def display_slots_table(display=true)
    if(request.post? && params[:table_action] && params[:slot].is_a?(Hash)) 
      CalendarSlot.destroy(params[:slot].keys) if params[:table_action] == 'delete'
    end
  
  
    @active_table_output = slots_table_generate(params,:order => 'calendar_slots.name',:include => :calendar_slot_group)
    
    render :partial => 'slots_table' if display
  end
  
  
  
  def index
     cms_page_path [ "Content", "Appointments"],"Configure"
     display_slots_table(false)
  end
  
  
  active_table :availabilities_table,
                CalendarAvailability,
                [ ActiveTable::IconHeader.new('', :width=>10),
                  ActiveTable::DateRangeHeader.new('start_on', :label => 'Starting On'),
                  ActiveTable::OptionHeader.new('availability_type',:options => :availabilities_options ),
                  ActiveTable::StaticHeader.new('Description'),
                  ActiveTable::DateRangeHeader.new('end_on',:label => 'Ending'),
                  
                ]  
  def availabilities_options
    CalendarAvailability.availability_type_select_options
  end
                
  def display_availabilities_table(display=true)
    @slot ||= CalendarSlot.find(params[:path][0]) 
  if(request.post? && params[:table_action] && params[:availability].is_a?(Hash)) 
    CalendarAvailability.destroy(params[:availability].keys) if params[:table_action] == 'delete'
   end

  
    @active_table_output = availabilities_table_generate params, :order => 'start_on', :conditions =>
                ['(end_on > NOW() OR end_on IS NULL) AND calendar_slot_id = ?',params[:path][0]]
                
    render :partial => 'availabilities_table' if display
  end
  
  def availabilities
     @slot = CalendarSlot.find(params[:path][0])
     cms_page_path [ "Content", "Appointments","Configure"],  [ 'Edit %s Availability', nil, @slot.name ]
     
      display_availabilities_table(false)
  end
  
  
  def availability
    @availability = CalendarAvailability.find_by_id(params[:path][0]) || 
                      CalendarAvailability.new()
    @slot = CalendarSlot.find_by_id(@availability.calendar_slot_id)
    cms_page_path [ "Content", "Appointments","Configure" ] +
                  (@availability.id ? [[   'Edit %s Availability', url_for(:action => 'availabilities', :path => @slot.id), @slot.name ]] : [] )  , 
                  @availability.id ? "Edit Availability" : "Create Availability"
                  
    @main_calendar = params[:main]
                  
    @availability.attributes =  params[:availability] if params[:availability]
    
    
                      
    if request.post? && params[:availability] && @availability.valid?
      if params[:availability][:calendar_slot_id] =~ /^Group([0-9]+)$/
        group = CalendarSlotGroup.find($1)
        group.calendar_slots.each do |slot|
          slot_avail = @availability.clone
          slot_avail.calendar_slot_id = slot.id
          slot_avail.save
        end
        redirect_to :controller => '/calendar/manage'
      else
        @availability.save
        if @main_calendar.to_s == '1'
          redirect_to :controller => '/calendar/manage'
        else
          redirect_to :action => 'availabilities', :path => @availability.calendar_slot_id
        end      
      end
      return 
    end
    
    @slots = CalendarSlot.find_select_options(:all,:order => 'name')
    if !@availability.id
      @slots = CalendarSlotGroup.find(:all,:order => 'calendar_slot_groups.name',:include => :calendar_slots).collect { |sg|
            [ " #{sg.name} Group (#{sg.calendar_slots.length})", "Group#{sg.id}" ]
          } + [[ '---','']] + @slots
    end
    
    
    
  end
  
  def edit
     @slot = CalendarSlot.find_by_id(params[:path][0]) || CalendarSlot.new()
     cms_page_path [ "Content", "Appointments","Configure"],  @slot.id ? 'Edit Slot' : 'Create Slot'
  
      if request.post? && params[:slot]
        @new_slot = !@slot.id
        if @slot.update_attributes(params[:slot])
          redirect_to :action => 'index' 
          return 
        end
      end
      
      @slot_groups = [ [ '--Select a Slot Group--','']] + CalendarSlotGroup.find_options(:all,:order => 'name')
      
  end
  
  
  active_table :groups_table,
                CalendarSlotGroup,
                [ ActiveTable::IconHeader.new('', :width=>10),
                  ActiveTable::StringHeader.new('calendar_slot_groups.name',:label => 'Name')
                ]
                
  def display_groups_table(display=true)
    if(request.post? && params[:table_action] && params[:group].is_a?(Hash)) 
      CalendarSlot.destroy(params[:group].keys) if params[:table_action] == 'delete'
    end

    @active_table_output = groups_table_generate(params,:order => 'name')
    
    render :partial => 'groups_table' if display
  end

  
  def groups
    cms_page_path [ "Content","Appointments", "Configure" ], "Slot Groups"
  
    display_groups_table(false)
  
  end
  
  def group_edit  
    @group = CalendarSlotGroup.find_by_id(params[:path][0]) || CalendarSlotGroup.new()
    
    cms_page_path ['Content','Calendar','Configure Calendar','Slot Groups' ], @group.id ? "Edit Group" : 'Create Group'
                
    if request.post? && params[:group]
      @new_grp = !@group.id
      if @group.update_attributes(params[:group])
        flash[:notice] = @new_grp ? "Created %s Group" / @group.name  : 'Updated %s Group' / @group.name
        cms_page_redirect('Slot Groups')
      end
    end   
  end
end
