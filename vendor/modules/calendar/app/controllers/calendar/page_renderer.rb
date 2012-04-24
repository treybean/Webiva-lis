require 'icalendar'


class Calendar::PageRenderer < ParagraphRenderer

  module_renderer
  
  paragraph :month_schedule
  paragraph :day_schedule
  paragraph :booking
  paragraph :user_bookings
  paragraph :ical
  
  feature :calendar_month_schedule, :default_feature => <<-FEATURE
    <cms:calendar>
      <div style='float:left'>
       <cms:previous>
        <a <cms:href/> > &lt;&lt; Previous Month</a>
       </cms:previous>
      </div>
      <cms:next>
      <div style='float:right'>
        <a <cms:href/> > Next Month &gt;&gt;</a>
      </div>
      </cms:next>
      <div align='center'>
        <cms:date/>
      </div>
      <div style='clear:both;'></div>
      <table cellpadding='0' cellspacing='0'>
       <tr>
        <cms:day_labels>
        <td align='center'>
           <cms:label/>
        </td>
        </cms:day_labels>
       </tr>
       <cms:week>
       <tr>
       <cms:day>
       <td>
        <cms:display/>
       </td>
       </cms:day>       
       </tr>       
       </cms:week>
      </table>
    
    </cms:calendar>
  FEATURE
  
  @@day_labels = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday' ]
  @@day_labels_short = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
  
  include Calendar::ManageHelper
  
   def calendar_month_schedule_feature(feature,data)
    parser_context = FeatureContext.new do |c|

      c.define_tag 'calendar' do |tag|
        tag.expand
      end
      
      c.define_tag('calendar:previous') { |tag| tag.expand }
      c.define_tag 'calendar:previous:href' do |tag|
        "href='#{site_node.node_path}/#{data[:previous_month]}'"
      end
      
      c.define_tag('calendar:next') { |tag| tag.expand }
      c.define_tag 'calendar:next:href' do |tag|
        "href='#{site_node.node_path}/#{data[:next_month]}'"
      end
      
      c.define_date_tag('calendar:date') do |tag|
        data[:date]
      end
      
      c.define_tag('calendar:day_labels') do |tag|
        labels = tag.attr['short'] ? @@day_labels_short : @@day_labels
        output = ''
        labels.each do |lbl|
          tag.locals.day_label = lbl.t
          output += tag.expand
        end
        output
      end
      
      c.define_tag('calendar:day_labels:label') { |tag| tag.locals.day_label }
      
      c.define_tag('calendar:week') do |tag|
        output = ''
        @blocks.each do |week|
          tag.locals.week = week
          output += tag.expand
        end
        output
      end
      
      c.define_tag('calendar:week:day') do |tag|
        output = ''
        c.each_local_value(tag.locals.week,tag,'day')
      end
      
      c.define_position_tags('calendar:week:day')
      
      c.define_tag('calendar:week:day:display') do |tag|
        day = tag.locals.day
       
        if tag.attr['short']
          day_label = day[:date].day.to_s
        else
          day_label = "#{day[:date].strftime("%B") if day[:date].day == 1} #{day[:date].day}"
        end
        
        if tag.attr['current']
          day_label ='' unless day[:date].month == @visible_month 
        else
          day_label = "<b>#{day_label}</b>" if day[:date].month == @visible_month  
        end
        
        slots = ''
        if tag.attr['group']
          (day[:slots]||{}).each do |slot_id,slot|
            slot.each do |block|
              slots += "<a href='#{data[:detail_page]}/#{day[:date].strftime("%Y-%m-%d")}' style='#{calendar_full_block_style(block,0,0, :color => tag.attr['color'],:height => data[:block_height])}' title='#{vh(block[:description])}' ></a>"
            end
          end
        else
          (day[:slots]||{}).each do |slot_id,slot|
            slot.each do |block|
              slots += "<a href='#{data[:detail_page]}/#{day[:date].strftime("%Y-%m-%d")}' style='#{calendar_block_style(block,0,0,:color => tag.attr['color'])}' title='#{vh(block[:description])}' ></a>"
            end
          end
        end
        
        <<-EOT
         <div style='position:relative;height:#{data[:block_height]}px;width:#{data[:block_width]}px;'>
            <div style='position:absolute; right:#{data[:block_width] < 35 ? 1 : 4 }px;  top:#{data[:block_height] < 35 ? 1 : 4 }px; z-index:10;'>#{day_label}</div>
            #{slots}
         </div>
        EOT
      
      end
      
    end
      
    parse_feature(feature,parser_context)
  end
   
  
  def month_schedule
  
    # 
    schedule_connection,schedule_link = page_connection()
    display_schedule = schedule_link.to_s.split("-")
    
    current_date = Time.now
    @visible_year = (display_schedule[0].to_i > 1900) ? display_schedule[0].to_i : current_date.year
    @visible_month = (display_schedule[1].to_i > 0 && display_schedule[1].to_i <= 12) ? display_schedule[1].to_i : current_date.month
    
    if(@visible_year > current_date.year + 10)
      raise SiteNodeEngine::MissingPageException.new(nil,nil)
    end

    @visible_date = Time.local(@visible_year,@visible_month,1)
  
    display_string = "#{@visible_year}_#{@visible_month}"
    feature_output,expires_time = DataCache.get_content('Calendar','MonthSchedule',display_string ) unless editor? || myself.id
  
    if !feature_output || !expires_time || expires_time < current_date
      options = Calendar::PageController::MonthScheduleOptions.new(paragraph.data || {})
      
      detail_page =  SiteNode.get_node_path(options.day_page_id,'#')
      
     # Get the visible days of the catalog
      @days = Calendar::Utility.generate_visible_days(@visible_month,@visible_year)
      
      if options.display != 'user'
        # Get all the availabilities, bookings and holidays
        @calendar = Calendar::Utility.generate_calendar(@days)
        
        # Turn into blocks
        @blocks = Calendar::Utility.generate_blocks(@calendar)
        
        @blocks = Calendar::Utility.clear_bookings(@blocks) if options.display != 'all'
        @blocks = Calendar::Utility.group_slots(@blocks) if options.display == 'group' || options.display == 'schedule'
      else
        @blocks = Calendar::Utility.generate_blocks(@days[:days])
        @blocks = Calendar::Utility.group_slots(@blocks)
      end
      
      @blocks = Calendar::Utility.add_bookings(@blocks,myself) if options.display == 'schedule' || options.display == 'user'
      
      next_month = @visible_date.next_month.strftime("%Y-%m")
      previous_month  = @visible_date.last_month.strftime("%Y-%m")
      
      
      @blocks = Calendar::Utility.format_block(@blocks,options.block_width,options.block_height)
      
      data = { :blocks => @blocks, :previous_month => previous_month, :next_month => next_month, :date => @visible_date,
               :block_width => options.block_width, :block_height => options.block_height, :detail_page => detail_page }
      feature_output = calendar_month_schedule_feature(get_feature('calendar_month_schedule'),data)

      DataCache.put_content("Calendar",'MonthSchedule',display_string,[feature_output,current_date + 15.minutes]) unless editor? || myself.id
    end
    render_paragraph :text => feature_output
  end
  
  feature :calendar_day_schedule, :default_feature => <<-FEATURE
    <cms:calendar>
        <div style='float:left'>
         <cms:previous>
          <a <cms:href/> > &lt;&lt; Previous Day</a>
         </cms:previous>
        </div>
        <cms:next>
        <div style='float:right'>
          <a <cms:href/> > Previous Day &gt;&gt;</a>
        </div>
        </cms:next>
        <div align='center'>
          <cms:date/>
        </div>
        <div style='clear:both;'></div>
        <table cellpadding='0' cellspacing='0'>
        <cms:time_block>
        <tr>
          <td><cms:label/></td>
          <cms:slot>
          <td>
            <a <cms:href/> <cms:style/>></a>
          </td>
          </cms:slot>
        </tr>
        </cms:time_block>
        </table>
      </cms:calendar>
  FEATURE

 
  def calendar_day_schedule_feature(feature,data)
    slot_indexes = data[:day][:slots].keys
    
    parser_context = FeatureContext.new do |c|

      c.define_tag 'calendar' do |tag|
        tag.expand
      end  
      
      c.define_tag('calendar:previous') { |tag| tag.expand }
      c.define_tag 'calendar:previous:href' do |tag|
        "href='#{site_node.node_path}/#{data[:yesterday]}'"
      end
      
      c.define_tag('calendar:next') { |tag| tag.expand }
      c.define_tag 'calendar:next:href' do |tag|
        "href='#{site_node.node_path}/#{data[:tomorrow]}'"
      end
      
      c.define_date_tag('calendar:date') do |tag|
        data[:date]
      end      
      
      c.define_tag('calendar:time_block') do |tag|
        output = ''
        data[:day][:blocks].each_with_index do |block,idx|
          tag.locals.idx = idx
          tag.locals.block = block
          output += tag.expand
        end
        output
      end
      
      c.define_tag('calendar:time_block:label') do |tag|
        fmt = tag.attr['fmt'] || nil
        display = tag.attr['display']
        case display
        when 'start':
          Calendar::Utility.time_str(tag.locals.block[0],fmt)
        when 'end':
          Calendar::Utility.time_str(tag.locals.block[1],fmt)
        else
          "#{Calendar::Utility.time_str(tag.locals.block[0],fmt)} - #{Calendar::Utility.time_str(tag.locals.block[1],fmt)}"
        end        
          
      end
      
      c.define_tag('calendar:time_block:slot') do |tag|
        output = ''
        slot_indexes.each do |slot_index|
          tag.locals.slot = data[:day][:slots][slot_index][tag.locals.idx]
          output += tag.expand
        end
        output
      end
      
      c.define_expansion_tag('calendar:time_block:slot:available') { |tag|  tag.locals.slot[2].is_a?(CalendarAvailability) }
      c.define_expansion_tag('calendar:time_block:slot:booked')  { |tag| tag.locals.slot[2].is_a?(CalendarBooking) }
      
      c.define_tag('calendar:time_block:slot:href') do |tag|
        if data[:booking_page] && tag.locals.slot[2] && tag.locals.slot[2].is_a?(CalendarAvailability)
          "href='#{data[:booking_page]}?calendar_book[date]=#{data[:date].strftime("%Y-%m-%d")}&calendar_book[time]=#{tag.locals.block[0]}'"
        elsif data[:booking_page] && tag.locals.slot[2] && tag.locals.slot[2].is_a?(CalendarBooking)
          "href='#{data[:member_page]}?calendar_book[edit]=#{tag.locals.slot[2].id}' title='#{vh tag.locals.slot[2].get_description(nil,nil,:override => "Trainer")}' "
        else
          "href='javascript:void(0);'"
        end
      end
      
      c.define_tag('calendar:time_block:slot:style') do |tag|
        if tag.locals.slot[2]
          color = tag.locals.slot[2].get_color 
        else
          color = '#FFFFFF'
        end
      
        if tag.attr['hover'] && tag.locals.slot[2] 
          mouseover = "onmouseover='this.style.backgroundColor=\"#{tag.attr['hover']}\";' onmouseout='this.style.backgroundColor=\"#{color}\";'"
        end
        
        "style='display:block; background-color:#{color}; width:#{data[:block_width]}px;height:#{data[:block_height]}px;' #{mouseover}"
      end
      
      
    end
    parse_feature(feature,parser_context)
  end
  
  def day_schedule
    schedule_connection,schedule_link = page_connection()
    display_schedule = schedule_link.to_s.split("-")
    
    current_date = Time.now
    @visible_year = (display_schedule[0].to_i > 1900) ? display_schedule[0].to_i : current_date.year
    @visible_month = (display_schedule[1].to_i > 0 && display_schedule[1].to_i <= 12) ? display_schedule[1].to_i : current_date.month
    @visible_day = (display_schedule[2].to_i > 0)  ? display_schedule[2].to_i : current_date.day
    
    @visible_date = Time.local(@visible_year,@visible_month,@visible_day)
  
    display_string = "#{@visible_year}_#{@visible_month}_#{@visible_day}"
    feature_output = DataCache.get_content('Calendar','DaySchedule',display_string ) unless editor? || myself.id
  
    if !feature_output 
      options = Calendar::PageController::DayScheduleOptions.new(paragraph.data || {})
      
     # Get the visible days of the catalog
      @days = Calendar::Utility.generate_visible_day(@visible_date)
      
      
      # Get all the availabilities, bookings and holidays
      @calendar = Calendar::Utility.generate_calendar(@days)
      
      # Turn into blocks
      @blocks = Calendar::Utility.generate_blocks(@calendar)
      
      @blocks = Calendar::Utility.clear_bookings(@blocks) if options.display != 'all'
      #@blocks = Calendar::Utility.group_slots(@blocks) if options.display == 'group' || options.display == 'schedule'
      
      @blocks = Calendar::Utility.add_bookings(@blocks,myself) if options.display == 'schedule'
      
      @day = @blocks[0][0]
      
      @module_options = Calendar::Utility.options

      @signup_options = Calendar::Utility.signup_blocks(@day, :block_minutes => options.block_minutes,
                                                              :signup_length => options.signup_length,
                                                              :start_time => @module_options.start_time,
                                                              :end_time => @module_options.end_time,
                                                              :group => (options.display == 'group' || options.display == 'schedule') ? true : false )

      booking_page = options.booking_page_id ? SiteNode.get_node_path(options.booking_page_id) : nil

      tomorrow = @visible_date.tomorrow.strftime("%Y-%m-%d")
      yesterday  = @visible_date.yesterday.strftime("%Y-%m-%d")
      
      data = { :day => @signup_options, :tomorrow => tomorrow, :yesterday => yesterday, :date => @visible_date,
               :block_width => options.block_width, :block_height => options.block_height,
               :booking_page => booking_page
             }
      feature_output = calendar_day_schedule_feature(get_feature('calendar_day_schedule'),data)

      DataCache.put_content("Calendar",'DaySchedule',display_string,feature_output) unless editor? || myself.id
    end
    render_paragraph :text => feature_output
  
  end
  
 feature :calendar_booking, :default_feature => <<-FEATURE
    <cms:bookings>
    <table>
      <cms:booking>
        <tr>
          <td><cms:description/></td>
          <td><cms:remove>Remove</cms:remove></td>
        </tr>
      </cms:booking>
    </table>
    </cms:bookings>
    <cms:options>
    <table width='100%'>
    <tr>
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
          <cms:book><cms:button>Book Using <cms:book_credits/> Credits</cms:button></cms:book> 
          <cms:no_book>You need <cms:book_credits/> to Book these sessions</cms:no_book>
        </cms:user>
      </td>
      <td>
        Click the button below to go back to the schedule and add more sessions to your cart.
        <cms:select>Select More Sessions</cms:select>
      </td>
      <td>
        Click the button below to add the selected sessions to your cart and checkout.
        <cms:checkout>Checkout</cms:checkout>
      </td>
    </tr>
    </table>
    </cms:options>
    <cms:no_bookings>
      <cms:booked>
      Your bookings have been confirmed
      </cms:booked>
      <cms:no_booked>
        You currently have no unconfirmed bookings
      </cms:no_booked>
      
      <cms:select>Select More Sessions</cms:select>
    </cms:no_bookings>
  FEATURE


 
  def calendar_booking_feature(feature,data)
    
    parser_context = FeatureContext.new do |c|
      c.define_expansion_tag('bookings') { |tag| data[:bookings].length > 0 }

        c.define_tag 'bookings:booking' do |tag|
          c.each_local_value(data[:bookings],tag,'booking') 
        end
        
          c.define_tag('bookings:booking:description') { |tag| tag.locals.booking.cart_details }
          c.define_date_tag('bookings:booking:date') { |tag| tag.locals.booking.booking_on }
          c.define_value_tag('bookings:booking:time') { |tag| tag.locals.booking.time }
          c.define_value_tag('bookings:booking:start_time') { |tag| tag.locals.booking.to_start_time.strftime('%H:%M%I') }
          
          c.define_post_button_tag('bookings:booking:remove') { |tag| "#{data[:node_path]}?calendar_remove_booking=#{tag.locals.booking.id}" }
      
      c.define_tag 'options' do |tag|
        data[:bookings].length > 0 ? tag.expand : nil
      end
      
      c.define_login_block('options:login',data[:login_error]) { myself }
      c.define_tag('options:user') { |tag| myself.id ? tag.expand : nil }
      
      c.define_value_tag('options:user:credits') { |tag| data[:credits] }
      c.define_expansion_tag( 'options:user:book') { |tag| data[:credits] >= data[:bookings].length }
        c.define_post_button_tag('options:user:book:button') { |tag| "#{data[:node_path]}?calendar_confirm_bookings=credit" }
        c.define_post_button_tag('options:user:no_book:button') { |tag| "#{data[:node_path]}?calendar_buy_more=1" }
        
      c.define_value_tag('book_credits') { |tag| data[:bookings].length }      
      c.define_value_tag('booked') { |tag| data[:booked] }
      
      c.define_post_button_tag('select', :method => 'get') { |tag| data[:calendar_path] }
      c.define_post_button_tag('options:checkout') { |tag| "#{data[:node_path]}?calendar_confirm_bookings=checkout" }
     
    end
    parse_feature(feature,parser_context)
  end  
  
  
  def booking
      options = Calendar::PageController::BookingOptions.new(paragraph.data || {})
      
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
      
      # Verify availability of each of the existing bookings
      # if expired and no longer available -> remove them
      session[:calendar] ||= {}
      session[:calendar][:booking_ids] ||= []
      
      if options.auto_book && !editor?
        if confirm_all_bookings
          redirect_paragraph :site_node => options.auto_book_page_id
          return
        end
      end      
      
      return if handle_booking(options)
      
      if session[:calendar][:booking_ids].length > 0
        unconfirmed_bookings = CalendarBooking.find(:all,:conditions => [ 'confirmed = 0 AND id IN (?)',session[:calendar][:booking_ids] ])
      else
        unconfirmed_bookings = []
      end
      
      cu = CalendarUser.user(myself)
      
      data = {:bookings => unconfirmed_bookings, :credits => cu.credits,
              :node_path => site_node.node_path,
              :calendar_path => SiteNode.get_node_path(options.calendar_page_id),
              :checkout_page => SiteNode.get_node_path(options.checkout_page_id),
              :login_error => login_error,
              :booked => flash[:booking_booked] }
      
      feature_output = calendar_booking_feature(get_feature('calendar_booking'),data)
  
      render_paragraph :text => feature_output
  end
  
  def handle_booking(options)
  
   if params[:calendar_book]
      booking = params[:calendar_book]
      
      if booking[:date] && booking[:time]
        @date = Time.parse(booking[:date])
        @start_time = booking[:time].to_i
        @end_time = @start_time + options.booking_minutes
        
        if slot_ids = Calendar::Utility.availability?(options.slot_id,@date,@start_time,@end_time)
            slot_id = Calendar::Utility.find_best_slot(myself,slot_ids)
        
            @booking = CalendarBooking.create(:calendar_slot_id => slot_id, 
                                              :booking_on => @date,
                                              :start_time => @start_time,
                                              :end_time => @end_time,
                                              :end_user_id => myself.id,
                                              :recipient_name => myself.id ? myself.name : "Anonymous User at " + request.remote_ip,
                                              :valid_until => Time.now + options.minutes_hold_time.to_i.minutes)
          if @booking 
            session[:calendar][:booking_ids] << @booking.id
            DataCache.expire_content("Calendar")
          else
            flash[:booking_notice] = "The Selected #{Calendar::Utility.options.booking_name} is currently unavailable"
          end
          redirect_paragraph :page # Redirect to this node to prevent attempted rebookings
          return true
          
        end
      end
    elsif params[:calendar_buy_more] && request.post?
      @cart = get_cart
      product = Shop::ShopProduct.find_by_id(options.booking_credit_product_id)
      
      if product
        @cart = get_cart
        @cart.products.each do  |prd|
          if prd.cart_item.class == CalendarBooking
            @cart.edit_product(prd.cart_item,0,{})
          end
        end
        @cart.edit_product(product,1,{})
        redirect_paragraph :site_node => options.checkout_page_id
        return true
      end
    
    elsif params[:calendar_remove_booking] && request.post?
      if session[:calendar][:booking_ids].include?(params[:calendar_remove_booking].to_i)
        booking = CalendarBooking.find_by_id(params[:calendar_remove_booking].to_i)
        if booking
          @cart = get_cart
          @cart.edit_product(booking,0,{})
          booking.destroy
          flash[:booking_notice] = "Your #{Calendar::Utility.options.booking_name} was removed"
        end
        redirect_paragraph :page # Redirect to this node to prevent attempted rebookings
        return true
      end
    elsif params[:calendar_confirm_bookings] && request.post?
      if  params[:calendar_confirm_bookings] == 'checkout'
        @cart = get_cart
        session[:calendar][:booking_ids].each do |booking_id|
          booking = CalendarBooking.find_by_id(booking_id)
          
          if booking
            @cart.add_product(booking,1,{})
          end
        end
        redirect_paragraph :site_node => options.checkout_page_id
        return true
#        prd = Shop::ShopProduct.find_by_id(act[:product])
#        return false unless prd
#        options = { :variations => {}}
#        prd.variations.each do |variation|
#          option_id = act[:variation][variation.id.to_s]
#          option = variation.options.find_by_id(option_id)
#          return false unless option
#          options[:variations][variation.id] = option.id
#        end
#        paragraph_action('Add to Cart: %s' / prd.name)
#        @cart.add_product(prd,(act[:quantity] || 1).to_i,options)
#        flash[:shop_product_added] = prd.id
#        return true
      elsif params[:calendar_confirm_bookings] == 'credit'
        return confirm_all_bookings
      end
    end
    return false
  
  end
  
  def confirm_all_bookings
    DomainModel.transaction do
      cu = CalendarUser.user(myself)
      bookings_to_confirm = []
      session[:calendar][:booking_ids].each do |booking_id|
        booking = CalendarBooking.find_by_id_and_confirmed(booking_id,0,:lock => true)
        bookings_to_confirm << booking if booking
      end
      if cu.credits >= bookings_to_confirm.length && bookings_to_confirm.length > 0
        CalendarUser.update_credits(myself,-bookings_to_confirm.length ,"Booked:" + bookings_to_confirm.map(&:time_description).join(", "))
        bookings_to_confirm.each do |bk|
          bk.update_attribute(:confirmed,1)
        end
        flash[:booking_booked] = bookings_to_confirm.length
        return true
      end
    end
    return false
  end
  
  include Shop::CartUtility
  
  feature :calendar_user_bookings, :default_feature =>  <<-FEATURE
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
  
  def calendar_user_booking_feature(feature,data)
    parser_context = FeatureContext.new do |c|
      now = Time.now
      c.define_value_tag('ical') { |t| data[:ical] }
      c.define_value_tag('cancellation_hours') { |tag| data[:options].cancellation_hours }
      c.define_value_tag('notice') { |tag| data[:booking_notice] }
      c.define_value_tag('credits') { |tag| data[:credits] }
      c.define_expansion_tag('bookings') { |tag| data[:bookings].length > 0 }

        c.define_tag 'bookings:booking' do |tag|
          c.each_local_value(data[:bookings],tag,'booking') 
        end
        
          c.define_tag('bookings:booking:description') { |tag| tag.locals.booking.cart_details }
          c.define_date_tag('bookings:booking:date') { |tag| tag.locals.booking.booking_on }
          c.define_value_tag('bookings:booking:time') { |tag| tag.locals.booking.time }
          c.define_value_tag('bookings:booking:start_time') { |tag| tag.locals.booking.to_time.strftime('%I:%M %p') }
          
          c.define_expansion_tag('bookings:booking:cancel') { |tag| (tag.locals.booking.to_time - data[:options].cancellation_hours.hours) > now }
          c.define_post_button_tag('bookings:booking:cancel:button') { |tag| "#{data[:node_path]}?calendar_cancel_booking=#{tag.locals.booking.id}" }
    end
    parse_feature(feature,parser_context)
  
  end
  
  def user_bookings
    options = Calendar::PageController::UserBookingsOptions.new(paragraph.data || {})
    
    if request.post? && params[:calendar_cancel_booking]
      if booking = CalendarBooking.find_by_id(params[:calendar_cancel_booking],:conditions => [ 'confirmed=1 AND end_user_id=? AND booking_on >= DATE(NOW())',myself.id ])
        if booking.to_time - options.cancellation_hours.hours > Time.now
          booking.destroy
          paragraph_action('Calendar Canceled Booking',booking.get_description)
          CalendarUser.update_credits(myself,1,"Canceled:" + booking.time_description)
          
          flash[:calendar_booking_notice] = "Your #{Calendar::Utility.options.booking_name} was cancelled"
          redirect_paragraph site_node.node_path
          return
        end
      end
    end
  
    bookings = CalendarBooking.find(:all,:conditions => [ 'confirmed = 1 AND end_user_id=? AND booking_on >= DATE(NOW())',myself.id ], :order => 'booking_on')
    
    if flash[:booking_booked]
          flash.now[:calendar_booking_notice] = "Your #{Calendar::Utility.options.booking_name} has been booked"
    end
  
    cu = CalendarUser.user(myself)
    data = {
      :bookings =>bookings,
      :site_node => site_node.node_path,
      :options => options,
      :booking_notice => flash[:calendar_booking_notice],
      :credits => cu.credits,
      :ical => cu.ical_hash
    }
    
    feature_output = calendar_user_booking_feature(get_feature('calendar_user_bookings'),data)

    render_paragraph :text => feature_output
  end
  

  def ical
    conn_type, ical_hash = page_connection

    cu = CalendarUser.find_by_ical_hash(ical_hash)

    if !cu
      render_paragraph :text => 'Invalid Calendar'
      return
    end

    cal = Icalendar::Calendar.new

    bookings = CalendarBooking.find(:all,:conditions => ['booking_on > ? AND confirmed=1 AND end_user_id=?',Time.now.yesterday.at_midnight,cu.end_user_id],:order => 'booking_on,start_time')

    bookings.each do |booking|
      event = Icalendar::Event.new
      event.start = booking.to_time.strftime("%Y%m%dT%H%M%S")
      event.end = booking.to_end_time.strftime("%Y%m%dT%H%M%S")
      event.summary = "Appointment at" + " " + booking.time
      cal.add_event(event)
    end

    events = EventsBooking.find(:all,:conditions => ['events_events.event_on > ? AND confirmed=1 AND end_user_id=?', Time.now.yesterday.at_midnight,cu.end_user_id],:joins => :events_event )

    events.each do |booking|
      event = Icalendar::Event.new
      event.start = booking.events_event.event_starts_at.strftime("%Y%m%dT%H%M%S")
      event.end = booking.events_event.event_ends_at.strftime("%Y%m%dT%H%M%S")
      event.summary = booking.events_event.short_description
      cal.add_event(event)
    end

    data_paragraph :data => cal.to_ical,:type => 'text/calendar', :disposition => 'inline; filename=calendar.cvs', :filename => 'calendar.vcs'


  end
  
end
