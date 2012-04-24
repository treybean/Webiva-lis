

class Events::CalendarRenderer < ParagraphRenderer

  features '/events/calendar_feature'

  paragraph :month_list, :ajax => true
  paragraph :upcoming_list
  paragraph :event_detail

  def month_list

    if ajax?
      schedule_link = params[:path][0]    
    else
      schedule_connection,schedule_link = page_connection(:path)
    end  
    display_schedule = schedule_link.to_s.split("-")
    
    current_date = Time.now
    @visible_year = (display_schedule[0].to_i > 1900) ? display_schedule[0].to_i : current_date.year
    @visible_month = (display_schedule[1].to_i > 0 && display_schedule[1].to_i <= 12) ? display_schedule[1].to_i : current_date.month
    
    @visible_date = Time.local(@visible_year,@visible_month,1)  
    show_private = false
  
    conn_type,conn_id = page_connection(:target)
    
    # If we have more than 1 target - assume we are a member of all the targets
    # TODO: Decide if want to change that or not
    if ajax?
      if session[:events_calendar_targets]
        @targets = session[:events_calendar_targets][1].map do |elm|
          elm[0].constantize.find(elm[1])
        end
        show_private = session[:events_calendar_targets][0]
      end
    elsif editor?
      @evt = EventsEvent.find(:first,:conditions => 'target_type IS NOT NULL')
      @target = @evt.target if @evt
      show_private = true
    elsif conn_type == :target
     
      @targets = [ conn_id ]
      
      if conn_id.respond_to?('is_member?')
        show_private = conn_id.is_member?(myself)
      else
        show_private = true      
      end
    elsif conn_type == :target_list
      @targets = conn_id.target_list if conn_id
      show_private = true
    else 
      @targets = []
    end

    @options = paragraph_options(:month_list)
    
    if @targets || @options.target_type == 'all'
      
      
      
      start_time = @visible_date
      end_time = @visible_date.at_end_of_month
      
      if @options.target_type == 'all'
        session[:events_calendar_targets] = nil
        calendar = EventsEvent.full_event_calendar(start_time,end_time)
      else
        session[:events_calendar_targets] = [show_private,@targets.map { |elm| [ elm.class.to_s, elm.id ] } ]
        calendar = EventsEvent.event_calendar(start_time,end_time,@targets,show_private)
      end
    
      next_month = @visible_date.next_month.strftime("%Y-%m")
      previous_month  = @visible_date.last_month.strftime("%Y-%m")
    
      data = { :calendar => calendar, :targets => @targets, :detail_page_url => SiteNode.node_path(@options.detail_page_id), :options => @options,:block_height => @options.block_height,:block_width=>@options.block_width, :paragraph => paragraph,
      :next_month => next_month,:previous_month => previous_month, :event_page_url => @options.detail_page_url,:date => @visible_date }
      
      if ajax?
        txt = events_calendar_month_list_feature(data)
      else
        txt = "<div id='paragraph_#{paragraph.id}'>#{events_calendar_month_list_feature(data)}</div>"
      end
      
      render_paragraph :text => txt
    else
      render_paragraph :text => ''
    end    
    
    require_js('prototype')
    require_js('user_application')
    
  end
  
  
  def upcoming_list
  
  
    conn_type,conn_id = page_connection
    
    if conn_type == :target
      @target = conn_id
    elsif editor?
      @evt = EventsEvent.find(:first,:conditions => 'target_type IS NOT NULL')
      @target = @evt.target if @evt
    end
    
    @options = paragraph_options(:upcoming_list)
    if @target || @options.target_type == 'all'
      start_time = Time.now
      end_time = start_time + 8.weeks
      
      
      if @target.respond_to?('is_member?')
        show_private = @target.is_member?(myself)
      else
        show_private = true      
      end
      
      show_private = show_private ? '' : ' AND is_private = 0'
      
      if @options.target_type == 'all'   
        events = EventsEvent.event_list(start_time,end_time, :limit => @options.max_events, :conditions => [ '1' + show_private])
      else
        events = EventsEvent.event_list(start_time,end_time, :limit => @options.max_events, :conditions => [ 'target_type =? AND target_id=?' + show_private,@target.class.to_s,@target.id])
     
      end
      
      
      set_page_connection(:mapped_events,[ @options.popup_page_url, Proc.new { EventsEvent.map_data(events) } ])
    
      if @target.respond_to?(:add_events_permission)
        add_events  = @target.add_events_permission(myself)
      else
        add_events = false
      end
    
      data = { :events => events, :add_events => add_events, :target => @target, :detail_page_url => SiteNode.node_path(@options.detail_page_id), :options => @options}
      
      render_paragraph :text => events_calendar_upcoming_list_feature(data)
    else
      render_paragraph :text => ''
    end
  end
  
  def event_detail
  
    @options = paragraph_options(:event_detail)
  
    event_type,event_id = page_connection(:event_id)
    target_type,@target = page_connection(:target)
    
    
    edit = params[:edit] 
    if @target 
      if @target.respond_to?('is_member?')
        show_private = @target.is_member?(myself)
      else
        show_private = true      
      end
      show_private = show_private ? '' : ' AND is_private = 0'    
    
      @event = EventsEvent.find_by_id(event_id,:conditions => [ 'target_type = ? AND target_id = ?' + show_private,@target.class.to_s,@target.id ] )
        
      if @target.respond_to?(:add_events_permission)
        add_events  = @target.add_events_permission(myself)
      else
        add_events = false
      end
    else
      @event = EventsEvent.find_by_id(event_id)
      
      @target = @event.target if @event
      if @target && @target.respond_to?(:add_events_permission)
        add_events  = @target.add_events_permission(myself)
      else
        add_events = false
      end
      
      if @event && @event.is_private? && @target.respond_to?('is_member?')
        @event = nil unless @target.is_member?(myself)
      end
    end 
    
    if @target == myself
      add_events = true
    end
    
    if !@target && @options.personal_events
      @target = myself
      add_events  = true
    end
    
    if edit && add_events && !@event && @target
      @event = EventsEvent.new(:target => @target, :duration => 60, :start_time => 13 * 60)
    end
    
    @location = @event.map_location if @event
    
    if request.post? && edit && add_events
    
      if params[:event_delete].to_i == 1
        @event.destroy
        deleted = true
      elsif params[:event]
        @event.attributes = params[:event].slice(:name,:subtitle,:location,:duration,:start_time,:event_on,:description)
        @event.admin_user_id = myself.id
        @event.open_booking = @options.open_booking
        
        valid = @event.valid?
        
        # Look for a location with these attributes, otherwise 
        if(@options.include_location)
          @location = MapLocation.existing_location(params[:location])
          @location = MapLocation.new(params[:location].slice(:address,:city,:state,:zip)) if(!@location)
          valid &&= @location.valid?
        end
        
        
        if(valid)
          if @location
            @location.save unless @location.id
            @event.map_location = @location
          end
          @event.save
          edit = false
        end
      end
    end
    
    
    require_js('prototype')
    require_js('user_application')

    
    data = { :target => @target, :event => @event, :location => @location, :edit => edit, :add_events => add_events, :deleted => deleted, :options => @options }
    
    render_paragraph :text => events_calendar_event_detail_feature(data)
  
  end


end
