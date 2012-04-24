

class Events::PageRenderer < ParagraphRenderer 

  
  paragraph :event_list
  paragraph :event_detail
  paragraph :user_bookings
  paragraph :instructor_list
  paragraph :instructor_detail
  paragraph :repeat_list
  
  
 feature :events_event_list, :default_feature => <<-FEATURE
  <cms:day>
    <b><cms:date/></b><br/>
    <cms:events>
      <cms:event>
       <div class='event'>
        <b><a <cms:detail_href/>><cms:name/></a></b><br/>
        <i><cms:start_time/><cms:by>, with <cms:value/></cms:by></i><br/>
        <cms:location><i><cms:value/></li></cms:location>
      </div>
      </cms:event>
    </cms:events>
    <cms:no_events>
       <div class='event'>-- No Events --</div>
    </cms:no_events>
  </cms:day>
  <cms:list>
    <cms:event>
    <div>
      <h2 ><cms:name/></h2>
      <cms:img align='left' border='15'/>
      <cms:by/>
      <p><cms:description/></p>      
      <cms:repeat>
        <cms:day/>'s <cms:start_time/><br/>
      </cms:repeat>
    </div>
    </cms:event>
  </cms:list>
  
  FEATURE
  
  def events_event_list_feature(data)
    webiva_feature('events_event_list') do |c|
      c.define_tag('day') { |tag| data[:days] ? c.each_local_value(data[:days],tag,'day') : nil }
      c.define_date_tag('day:date') { |tag| tag.locals.day[:time] }
      c.define_expansion_tag('day:location:events') { |tag| tag.locals.events.length > 0 }
      c.define_expansion_tag('day:events') { |tag| tag.locals.day[:events].length > 0 }
      c.define_tag('day:location') do |tag|
        locations = tag.attr['locations'].split(",").collect { |loc_id| loc_id.to_i }
        output = ''
        locations.each_with_index do |loc_id,idx|
          tag.locals.first = loc_id == locations.first
          tag.locals.last =  loc_id== locations.last
          tag.locals.index =  idx+1
          tag.locals.events = tag.locals.day[:events].find_all { |evt| evt.map_location_id == loc_id }
          output += tag.expand
        end
        output
      end
      c.define_expansion_tag('last_week') { |tag| data[:offset] > 0 }
      c.define_tag('last_week:href') { |tag| "href='?week=#{data[:offset]-1}'" }
      c.define_expansion_tag('next_week') { |tag| true }
      c.define_tag('next_week:href') { |tag| "href='?week=#{data[:offset]+1}'" }
      
      c.define_tag('day:events:event') { |tag| c.each_local_value(tag.locals.events || tag.locals.day[:events],tag,'event') }
      c.define_tag('day:event:detail_href') do |tag|
        editor? ? "href='javascript:void(0);'" : "href='#{data[:detail_url]}/#{tag.locals.event.id}'"
      end
      
      c.define_expansion_tag('event:space') { |tag| tag.locals.event.event_spaces > tag.locals.event.unconfirmed_bookings }
      
      c.define_expansion_tag('list') { |tag| data[:list] && data[:list].length > 0 }
      c.define_tag('list:event') { |tag| data[:list] ? c.each_local_value(data[:list],tag,'event') : nil }
      c.define_tag('list:event:detail_href') do |tag|
        editor? ? "href='javascript:void(0);'" : "href='#{data[:detail_url]}/#{tag.locals.event.id}?first=true'"
      end
      
      c.define_tag('event:repeat') do |tag| 
        tag.locals.parent_event = tag.locals.event.parent_event ? tag.locals.event.parent_event : tag.locals.event
        c.each_local_value(tag.locals.parent_event.events_repeats,tag,'repeat')
      end
      c.define_value_tag('event:repeat:day') { |tag| tag.locals.repeat.repeat_type_day_display }
      c.define_value_tag('event:repeat:start_time') { |tag| tag.locals.parent_event.start_time_display(tag.locals.repeat.start_time) }
      c.define_value_tag('event:repeat:by') do |tag|
        if tag.locals.repeat.events_instructor 
          tag.locals.repeat.events_instructor.name 
        elsif tag.locals.parent_event.events_instructor 
          tag.locals.parent_event.events_instructor.name 
        end
      end
      
      define_position_tags(c)
      define_event_tags(c,data)
    end
  end
  
  def event_list
  
    target_string = "List"
    offset = (params[:week] || 0).to_i
    offset = 0 if offset <= 0
    
    display_string = "#{paragraph.id}_#{myself.user_class_id}"

    current_time = Time.now

    options = Events::PageController::EventListOptions.new(paragraph.data)

    feature_output,valid_until = DataCache.get_content("Events",target_string,display_string) unless editor? || (options.display_type == 'schedule' && myself.id)
  
    if !feature_output || !valid_until || valid_until < current_time

      @start_time = Time.now - 1.days + offset.weeks
      
      opts = {}
      if options.events_credit_type_id.to_i > 0
        opts[:conditions] = ['events_credit_type_id=?',options.events_credit_type_id]
      end
      
      if  options.display_type == 'schedule'
        @events = EventsEvent.event_schedule(@start_time,@start_time.at_midnight + options.days_display.days, opts)
      else
        @event_list = EventsEvent.event_list(@start_time,@start_time.at_midnight + options.days_display.days, opts)
      end
      
      
      
      data = {:days => @events || [], :list => @event_list || [], :detail_url => SiteNode.get_node_path(options.detail_page_id), :offset => offset,
              :instructor_url => SiteNode.get_node_path(options.instructor_page_id) }
      feature_output = events_event_list_feature(data)
      
      DataCache.put_content("Events",target_string,display_string, [feature_output,current_time + 10.minutes ]) unless editor? || (options.display_type == 'schedule' && myself.id)
    end
    
    render_paragraph :text => feature_output
  
  end
  
  
  module EventFeature
   def define_event_tags(c,data)
        c.define_value_tag('event:event_id') { |tag| tag.locals.event.id }
        c.define_value_tag('event:name') { |tag| tag.locals.event.name }
        c.define_expansion_tag('event:is_private') { |tag| tag.locals.event.is_private? }
        c.define_value_tag('event:start_time') { |tag| tag.locals.event.start_time_display }
        c.define_value_tag('event:end_time') { |tag| tag.locals.event.end_time_display }
        c.define_date_tag('event:date') { |tag| tag.locals.event.event_on }      
        c.define_value_tag('event:by') { |tag| tag.locals.event.by }
        c.define_value_tag('event:location') { |tag| tag.locals.event.location }
        c.define_value_tag('event:description') { |tag| simple_format(h(tag.locals.event.description)) }
        c.define_value_tag('event:details') { |tag| tag.locals.event.details }
        c.define_image_tag('event:img') { |tag| tag.locals.event.image_file }
        c.define_image_tag('event:icon_img') { |tag| tag.locals.event.icon_file }
        c.define_value_tag('event:instructor_href') { |tag| "href='#{data[:instructor_url]}/#{tag.locals.event.events_instructor_id}'" }
        c.define_expansion_tag('event:myself') { |t| t.locals.event.target_id.to_i == myself.id }
        c.define_expansion_tag('event:target') { |t| t.locals.event.target }
          c.define_value_tag('event:target:name') { |t| t.locals.event.target.name if t.locals.event.target.respond_to?(:name) }
          c.define_image_tag('event:target:image') { |t| t.locals.event.target.image if t.locals.event.target.respond_to?(:image) }
    end
  end

  
 include EventFeature
  
feature :events_event_detail, :default_feature => <<-FEATURE
  <cms:event>
   <div class='event'>
    <b><cms:name/></b><br/>
    <i><cms:date/> <cms:start_time/><cms:by>, with <cms:value/></cms:by></i><br/>
    <cms:location><i><cms:value/></li></cms:location>
    <div>
      <cms:description/>
      <cms:details/>
    </div>
  </div>
  <cms:booked>
    You are signed-up for this event
  </cms:booked>
  <cms:full>
    This event is already full
  </cms:full>
  <cms:signup>
    <table width='100%'>
    <tr>
      <td>
        Purchase this class.
        <cms:checkout>Checkout</cms:checkout>
      </td>
      <td>
        <cms:login>
          Login below to use your exisiting credits:
          <cms:error>Invalid Login</cms:error>
          Email: <cms:email/><br/>
          Password: <cms:password/><br/>
          <cms:button>Login</cms:button>
        </cms:login>
        <cms:user>
          You currently have <cms:credits/> credits.<br/><br/>
          <cms:book><cms:button>Book Using 1 Credit</cms:button></cms:book> 
          <cms:no_book>You need credits to Book this event<br/>
                      <cms:button>Buy more Credits</cms:button>
          </cms:no_book>
        </cms:user>
      </td>
    </tr>
    </table>
  </cms:signup>  
  <cms:repeats>
    <cms:repeat>
      <cms:selected><b><cms:date/> <cms:start_time/><cms:by>, with <cms:value/></cms:by></b></cms:selected>
      <cms:unselected><a <cms:detail_href/>><cms:date/>  <cms:start_time/><cms:by>, with <cms:value/></cms:by></a></cms:unselected>
      <br/>
    </cms:repeat>
  </cms:repeats>
  </cms:event>
  <cms:no_event>
     Invalid Event
  </cms:no_event>
  FEATURE
  
  def events_event_detail_feature(data)
    upcoming_event = data[:event] ? (data[:event].event_starts_at > Time.now) : false
    webiva_feature('events_event_detail') do |c|
      c.define_expansion_tag('event') { |tag| tag.locals.event = data[:event] }
      define_event_tags(c,data)
      c.define_expansion_tag('event:space') { |tag| tag.locals.event.event_spaces > tag.locals.event.unconfirmed_bookings }
      
      
      c.define_expansion_tag('full') { |tag| upcoming_event && !data[:booking] && !data[:event].available? }
      c.define_expansion_tag('signup') { |tag| upcoming_event &&  !data[:booking] && data[:event].available? }
      c.define_expansion_tag('booked') { |tag| upcoming_event && data[:booking] }
      
      c.define_login_block('signup:login',data[:login_error]) { myself }
      c.define_tag('signup:user') { |tag| myself.id ? tag.expand : nil }
      
      c.define_value_tag('signup:user:credits') { |tag| data[:credits] }
      c.define_expansion_tag( 'signup:user:book') { |tag| data[:credits] >= 1 }
        c.define_post_button_tag('signup:user:book:button') { |tag| "#{data[:node_path]}?events_confirm_bookings=credit" }
        c.define_post_button_tag('signup:user:no_book:button') { |tag| "#{data[:node_path]}?events_buy_more=1" }
        c.define_post_button_tag('signup:user:buy_more_button') { |tag| "#{data[:node_path]}?events_buy_more=1" }
        
      c.define_post_button_tag('signup:checkout') { |tag| "#{data[:node_path]}?events_confirm_bookings=checkout" }
      
      c.define_expansion_tag('repeats') { |tag| tag.locals.event.upcoming_siblings.length > 0  }
      
      c.define_tag('repeats:group') do |tag|
        events = tag.locals.event.upcoming_siblings
        if tag.attr['limit'].to_i > 0
         events = events.slice(0,tag.attr['limit'].to_i)
        end
        
        groupings = []
        event_list = []
        events.each do |evt|
          grouping = evt.event_on.strftime(tag.attr['format'] || "%B %y")
          if !groupings.index(grouping)
            groupings << grouping
            event_list << []
          end
          idx = groupings.index(grouping)
          event_list[idx] << evt
        end
        
        c.each_local_value(groupings.zip(event_list),tag,"grouping")
      
      end
      c.define_tag('repeats:group:name') { |tag| tag.locals.grouping[0] }

      c.define_tag('repeats:repeat') { |tag| c.each_local_value(tag.locals.grouping ? (tag.locals.grouping[1]||[]) : tag.locals.event.upcoming_siblings,tag,'repeat') }
      c.define_expansion_tag('repeats:repeat:selected') { |tag| tag.locals.repeat.id == tag.locals.event.id }
      c.define_expansion_tag('repeats:repeat:unselected') { |tag| tag.locals.repeat.id != tag.locals.event.id }

      c.define_value_tag('repeat:name') { |tag| tag.locals.repeat.name }
      c.define_value_tag('repeat:start_time') { |tag| tag.locals.repeat.start_time_display }
      c.define_value_tag('repeat:end_time') { |tag| tag.locals.repeat.end_time_display }
      c.define_date_tag('repeat:date') { |tag| tag.locals.repeat.event_on }      
      c.define_value_tag('repeat:by') { |tag| tag.locals.repeat.by }
      c.define_value_tag('repeat:location') { |tag| tag.locals.repeat.location }
      c.define_value_tag('repeat:description') { |tag| simple_format(h(tag.locals.repeat.description)) }
      c.define_value_tag('repeat:details') { |tag| tag.locals.repeat.details }
      c.define_expansion_tag('repeat:space') { |tag| tag.locals.repeat.event_spaces > tag.locals.repeat.unconfirmed_bookings }

      c.define_value_tag('repeat:detail_href') { |tag| "href='#{site_node.node_path}/#{tag.locals.repeat.id}'" }

    end
  end  
  
  def event_detail
  
  
    if request.post? && params[:login]
      user = EndUser.login_by_email(params[:login][:email],params[:login][:password])
      if user
        session[:user_id] = user.id
        session[:user_model] = user.class.to_s
        reset_myself      
        redirect_paragraph :page
        return
      else 
        login_error = true
      end
    end  
  
    event_connection,event_id= page_connection()
    
    tm = Time.now.strftime("%Y%m%d")
    
    first = params[:first] ? 'first' : nil
    
    target_string = "#{event_connection}#{event_id}_#{first}"
    display_string = "#{paragraph.id}_#{myself.user_class_id}_#{tm}"

      
    # Only caching for anonymous users
    feature_output,class_title,parent_event_id = DataCache.get_content("Events",target_string,display_string) unless myself.id || request.post? || first

  
    if !feature_output
      if editor?
        event = EventsEvent.find(:first)        
      else
        event = EventsEvent.find_by_id(event_id)
        if first && event && event.parent_event_id
          event = EventsEvent.find(:first,:conditions => ["event_on >= CURDATE() AND (events_events.id=? OR parent_event_id = ?)",event.parent_event_id, event.parent_event_id ],:order => 'event_on, start_time')
          if event 
            redirect_paragraph site_node.node_path + "/" + event.id.to_s
            return
          end
        end
      end

      options = Events::PageController::EventDetailOptions.new(paragraph.data)
      if event      
        return if request.post? && handle_booking(event,options)
        event.update_unconfirmed!
      end
  
      if event
      data = {:event => event, 
              :credits => EventsUserCredit.get_credits(myself,event.events_credit_type_id), 
              :booking => EventsBooking.find_booking(myself,event), 
              :login_error => login_error,
              :instructor_url => SiteNode.get_node_path(options.instructor_page_id)  }
      else
        
        data = {}
      end
      feature_output = events_event_detail_feature(data)
      
      parent_event_id = event.parent_event_id ? event.parent_event_id : event.id if event
      
      class_title = event.name if event
      DataCache.put_content("Events",target_string,display_string, [feature_output,class_title,parent_event_id]) unless myself.id || request.post?
    end
    
    
    set_page_connection(:content_id, parent_event_id ? [ 'EventsEvent',parent_event_id ] : nil )
    
    set_title(class_title)
    
    render_paragraph :text => feature_output
  end
  
  
   def handle_booking(event,options)
  
    if params[:events_buy_more] && request.post?
      @cart = get_cart
      product = Shop::ShopProduct.find_by_id(options.booking_credit_product_id)
      
      if product
        @cart = get_cart
        @cart.products.each do  |prd|
          if prd.cart_item.class == EventsBooking
            @cart.edit_product(prd.cart_item,0,{})
          end
        end
        @cart.edit_product(product,1,{})
        redirect_paragraph :site_node => options.checkout_page_id
        return true
      end
    elsif params[:events_confirm_bookings] && request.post?
      if  params[:events_confirm_bookings] == 'checkout'
        @cart = get_cart
        booking = event.book_user_unconfirmed!(myself)
        if booking
          @cart.add_product(booking,1,{})
          redirect_paragraph :site_node => options.checkout_page_id
          return true
        else
          # Error Message
        end
        return false
      elsif params[:events_confirm_bookings] == 'credit'
        @result = event.book_user!(myself)
        if(!@result)
          redirect_paragraph :page
          return true
        end
      end
    end
    return false
  
  end
  
  include Shop::CartUtility  
  
 feature :events_user_bookings, :default_feature =>  <<-FEATURE
  <cms:notice><b><cms:value/></b></cms:notice>
  Bookings can only be cancelled <cms:cancellation_hours/> in advance.
  <cms:bookings>
  <table>
    <cms:booking>
      <tr>
        <td><cms:date/><br/><cms:description/></td>
        <td><cms:cancel><cms:button confirm="Cancel this booking?">Cancel Booking</cms:button></cms:cancel></td>
      </tr>
    </cms:booking>
  </cms:bookings>
  </table>
  
  FEATURE
    
 def events_user_booking_feature(data)
  webiva_feature('events_user_bookings') do |c|
      now = Time.now
      c.define_value_tag('cancellation_hours') { |tag| data[:options].cancellation_hours }
      c.define_value_tag('notice') { |tag| data[:booking_notice] }
      c.define_value_tag('credits')  { |tag| tag.attr['type'] ? data[:credits][tag.attr['type'].to_i] : (data[:credits].values||[])[0] }
      
      c.define_expansion_tag('user') { |tag| myself.id }
      c.define_expansion_tag('bookings') { |tag| data[:bookings].length > 0 }

        c.define_tag 'bookings:booking' do |tag|
          c.each_local_value(data[:bookings],tag,'booking') 
        end
        
          c.define_tag('bookings:booking:description') { |tag| tag.locals.booking.cart_details }
          c.define_date_tag('bookings:booking:date') { |tag| tag.locals.booking.events_event.event_starts_at }
          c.define_value_tag('bookings:booking:time') { |tag| tag.locals.booking.events_event.start_time_display }
          c.define_value_tag('bookings:booking:name') { |tag| tag.locals.booking.events_event.name }
          c.define_value_tag('bookings:booking:by') { |tag| tag.locals.booking.events_event.by }
          c.define_value_tag('bookings:booking:location') { |tag| tag.locals.booking.events_event.location }
          
          
          c.define_expansion_tag('bookings:booking:cancel') { |tag| (tag.locals.booking.events_event.event_starts_at - data[:options].cancellation_hours.hours) > now && !tag.locals.booking.events_event.no_cancel? }
          c.define_post_button_tag('bookings:booking:cancel:button') { |tag| "#{data[:node_path]}?events_cancel_booking=#{tag.locals.booking.id}" }
    end
  end    
    
  
 def user_bookings
    @opts = Events::AdminController.module_options
 
    options = Events::PageController::UserBookingsOptions.new(paragraph.data || {})

    day = Time.now.at_midnight
    
    if request.post? && params[:events_cancel_booking]
      if booking = EventsBooking.find_by_id(params[:events_cancel_booking],:conditions => [ 'confirmed=1 AND end_user_id=? AND  events_events.event_on >= DATE(?)',myself.id,day ], :joins => :events_event)
        if booking.events_event.event_starts_at - options.cancellation_hours.hours > Time.now && !booking.events_event.no_cancel?
          booking.destroy
          paragraph_action('Events Canceled Booking',booking.get_description)
          
          EventsUserCredit.refund_credit(myself,booking.events_event.events_credit_type_id, :description => booking.events_event.short_description)
          
          flash[:events_booking_notice] = "Your #{@opts.event_name} was cancelled"
          redirect_paragraph site_node.node_path
          return
        end
      end
    end
  
    bookings = EventsBooking.find(:all,:conditions => [ 'confirmed = 1 AND end_user_id=? AND events_events.event_on >= ?',myself.id,day.to_date ], :order => 'events_events.event_on', :joins => :events_event)
  
    credits = {}
    EventsUserCredit.find(:all,:conditions => ['end_user_id = ?',myself.id]).each do |uc| 
      credits[uc.events_credit_type_id] = uc.credits
    end
    data = {
      :bookings =>bookings,
      :site_node => site_node.node_path,
      :options => options,
      :booking_notice => flash[:events_booking_notice],
      :credits => credits
    }
    
    feature_output = events_user_booking_feature(data)

    render_paragraph :text => feature_output
  end  
  
  feature :instructor_list, :default_feature => <<-FEATURE
  <cms:instructors>
    <cms:instructor>
    <div style='clear:both;'>
      <cms:img align='left' size='preview'/>
      <h2><a <cms:detail_href/>><cms:name/></a></h2>
      <cms:description/><br/>
      <cms:classes/>
    </div>
    </cms:instructor>
  </cms:instructors>
  FEATURE
  
  def define_instructor_tags(c,data)
    c.define_value_tag('instructor:name') { |tag| h(tag.locals.instructor.name) }
    c.define_value_tag('instructor:description') { |tag| simple_format(h(tag.locals.instructor.description)) }
    c.define_value_tag('instructor:details') { |tag| tag.locals.instructor.details }
    c.define_image_tag('instructor:img') { |tag| tag.locals.instructor.image_file }
    c.define_tag('instructor:classes') do |tag|
      if data[:event_type]
        events = tag.locals.instructor.upcoming_events.find(:all,:conditions => { :events_credit_type_id => data[:event_type] })
      else
        events = tag.locals.instructor.upcoming_events
      end
      # Only want to show 1 event based on each parent - so get all upcoming events and group them by parent to pick out 1
      events.group_by() { |evt| evt.parent_event_id ? evt.parent_event_id : evt.id }.values.map do |event|
        event = event[0]
        "<a href='#{data[:event_url]}/#{event.id}?first=1'>#{h(event.name)}</a>"
      end.join(", ")
    end
    
  end

  def instructor_list_feature(data)
    webiva_feature('instructor_list') do |c|  
      c.define_expansion_tag('instructors') { |tag| data[:instructors].length > 0 }
      c.define_tag('instructors:instructor') { |tag| c.each_local_value(data[:instructors],tag,'instructor') }
    c.define_tag('detail_href') { |tag| "href='#{data[:detail_url]}/#{tag.locals.instructor.id}'" }
      
      
      define_instructor_tags(c,data)
    end
  end
  
  def instructor_list
    @options = Events::PageController::InstructorListOptions.new(paragraph.data)
  
  
    target_string = "Instructors"
    display_string = "#{paragraph.id}"
      
    feature_output = DataCache.get_content("Events",target_string,display_string) unless editor?

    if !feature_output
      instructors = EventsInstructor.find(:all,:order => 'events_instructors.name',:include => 'upcoming_events')
      
      data = { :instructors => instructors, 
               :event_url => SiteNode.node_path(@options.event_page_id),
               :detail_url => SiteNode.node_path(@options.detail_page_id),
               :event_type => @options.events_credit_type_id
              }
      
      feature_output = instructor_list_feature(data)
      
      DataCache.put_content("Events",target_string,display_string,feature_output) unless editor?
    end
    
    render_paragraph :text => feature_output
  end
  
  
 feature :instructor_detail, :default_feature => <<-FEATURE
    <cms:instructor>
    <div style='clear:both;'>
      <cms:img align='left' size='preview'/>
      <h2><cms:name/></h2>
      <cms:description/><br/>
      <cms:classes/><br/>
      <cms:details/>
    </div>
    </cms:instructor>
  FEATURE
  
  def instructor_detail_feature(data)
    webiva_feature('instructor_detail') do |c|  
      c.define_expansion_tag('instructor') { |tag| tag.locals.instructor = data[:instructor] }
      c.define_tag('list_href') { |tag| "href='#{data[:list_url]}'" }
      define_instructor_tags(c,data)
    end
  end
    
  
  def instructor_detail
    @options = Events::PageController::InstructorDetailOptions.new(paragraph.data)

    if @options.instructor_id.to_i > 0
      instructor_id = @options.instructor_id
    elsif !editor?
      instructor_connection,instructor_id= page_connection()
    end
      
    tm = Time.now.strftime("%Y%m%d")
    
    target_string = "#{instructor_connection}#{instructor_id}"
    display_string = "#{paragraph.id}_#{tm}"

      
    feature_output = DataCache.get_content("Events",target_string,display_string) unless editor?
      
     if !feature_output
      if editor? && !instructor_id
        instructor = EventsInstructor.find(:first)
      else
        instructor = EventsInstructor.find_by_id(instructor_id,:include => 'upcoming_events')
      end
      
      data = { :instructor => instructor, 
               :event_url => SiteNode.node_path(@options.event_page_id),
               :list_url => SiteNode.node_path(@options.list_page_id),
               :event_type => @options.events_credit_type_id
               
              }
      
      feature_output = instructor_detail_feature(data)
      
      DataCache.put_content("Events",target_string,display_string,feature_output) unless editor?
    end
    render_paragraph :text => feature_output
  end
  

 feature :events_repeat_list, :default_feature => <<-FEATURE
  <cms:day>
    <b><cms:date/></b><br/>
    <cms:events>
      <cms:event>
       <div class='event'>
        <b><a <cms:detail_href/>><cms:name/></a></b><br/>
        <i><cms:start_time/><cms:by>, with <cms:value/></cms:by></i><br/>
        <cms:location><i><cms:value/></li></cms:location>
      </div>
      </cms:event>
    </cms:events>
    <cms:no_events>
       <div class='event'>-- No Events --</div>
    </cms:no_events>
  </cms:day>
  FEATURE
    
  
  def events_repeat_list_feature(data)
    webiva_feature('events_repeat_list') do |c|
      c.define_tag('day') { |tag| c.each_local_value(data[:days],tag,'day') }
      c.define_date_tag('day:date','%A') { |tag| tag.locals.day[:time] }
      c.define_expansion_tag('day:location:events') { |tag| tag.locals.events.length > 0 }
      c.define_expansion_tag('day:events') { |tag| tag.locals.day[:events].length > 0 }
      c.define_tag('day:location') do |tag|
        locations = tag.attr['locations'].split(",").collect { |loc_id| loc_id.to_i }
        output = ''
        locations.each_with_index do |loc_id,idx|
          tag.locals.first = loc_id == locations.first
          tag.locals.last =  loc_id== locations.last
          tag.locals.index =  idx+1
          tag.locals.events = tag.locals.day[:events].find_all { |evt| evt.map_location_id == loc_id }
          output += tag.expand
        end
        output
      end
      c.define_tag('day:events:event') { |tag| c.each_local_value(tag.locals.events || tag.locals.day[:events],tag,'event') }
      c.define_tag('event:detail_href') do |tag|
        editor? ? "href='javascript:void(0);'" : "href='#{data[:detail_url]}/#{tag.locals.event.id}'"
      end
      define_position_tags(c)
      define_event_tags(c,data)
    end
  end
  
  def repeat_list
    now = Time.now
    tm = now.strftime("%Y%m%d")

    target_string = "Repeat"
    display_string = "#{paragraph.id}_#{myself.user_class_id}_#{tm}"
    feature_output,valid_until = DataCache.get_content("Events",target_string,display_string) unless  editor?
  
    if !feature_output || !valid_until ||  valid_until < now
      options = Events::PageController::EventRepeatListOptions.new(paragraph.data)
      
      opts = {}
      if options.events_credit_type_id.to_i > 0
        opts[:conditions] = ['events_credit_type_id=?',options.events_credit_type_id]
      end      
      
      @events = EventsEvent.weekly_schedule(Time.now,opts)

      data = {:days => @events, :detail_url => SiteNode.get_node_path(options.detail_page_id),
              :instructor_url => SiteNode.get_node_path(options.instructor_page_id) }
      feature_output = events_repeat_list_feature(data)
      
      DataCache.put_content("Events",target_string,display_string, [feature_output,now + 10.minutes]) unless editor?
    end
    
    render_paragraph :text => feature_output
  
  end  

end
