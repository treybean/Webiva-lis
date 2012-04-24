
class Events::PageController < ParagraphController

  editor_header 'Event Paragraphs'

  editor_for :event_list, :name => 'Event List', :features => ['events_event_list']
  editor_for :repeat_list, :name => 'Repeat List',:features => ['events_repeat_list']
                       
  editor_for :event_detail,  :name => 'Event Detail', :features => ['events_event_detail'],
                       :inputs => [ [ :event_id, 'Event ID', :path ]],
                       :outputs => [ [ :content_id, 'Content Identifier', :content ] ]
  
  editor_for :user_bookings, :name => 'User Bookings', :features => ['events_user_bookings']
  
  editor_for :instructor_list, :name => 'Instructor List', :features => ['instructor_list']
  editor_for :instructor_detail, :name => 'Instructor Detail', :features => ['instructor_detail'],
                       :inputs => [ [ :instructor_id, 'Instructor ID', :path ]]
  
  
  def event_list
  
    @options = EventListOptions.new(params[:event_list] || paragraph.data)
      
    return if handle_module_paragraph_update(@options)

    @per_page = (1..50).to_a
    @pages = SiteNode.page_options()
  end  
  
  class EventListOptions < HashModel
    default_options :per_page => 30, :detail_page_id => nil, :days_display => 7, :instructor_page_id => nil, :display_type => 'schedule', :events_credit_type_id => nil
    
    integer_options :per_page, :detail_page_id, :days_display, :instructor_page_id, :events_credit_type_id

    page_options :detail_page_id, :instructor_page_id
  end
  
  def event_detail
    @options = EventDetailOptions.new(params[:event_detail] || paragraph.data)
      
    return if handle_module_paragraph_update(@options)

    @pages = SiteNode.page_options()
    
     begin
        @products = Shop::ShopProduct.find_select_options(:all,:order => 'name')
      rescue 
        @products = []
      end    
  end

  class EventDetailOptions < HashModel
    default_options :list_page_id => nil, :checkout_page_id => nil, :booking_credit_product_id => nil, :minutes_hold_time => 5, :instructor_page_id => nil
    
    integer_options :list_page_id, :checkout_page_id, :booking_credit_product_id, :minutes_hold_time, :instructor_page_id

    page_options :list_page_id, :checkout_page_id, :instructor_page_id
  end

   def user_bookings
    @options = UserBookingsOptions.new(params[:user_bookings] || @paragraph.data)
    
    return if handle_module_paragraph_update(@options)
  end
  
  class UserBookingsOptions < HashModel
    default_options :cancellation_hours => 24, :allow_cancellations => 'yes'
    
    integer_options :cancellation_hours
    
  end
  
  
  def instructor_list
    @options = InstructorListOptions.new(params[:instructor_list] || @paragraph.data)
    @pages = SiteNode.page_options()
    return if handle_module_paragraph_update(@options)
  end
  
  class InstructorListOptions < HashModel
    default_options :detail_page_id => nil, :event_page_id => nil, :events_credit_type_id => nil 
    
    
    page_options :detail_page_id, :event_page_id
    
    integer_options :detail_page_id, :event_page_id, :events_credit_type_id
  end
  
  def instructor_detail
    @options = InstructorDetailOptions.new(params[:instructor_detail] || @paragraph.data)
    @pages = SiteNode.page_options()
    @instructors = [['--Use Page Connections--',nil]] + EventsInstructor.find_select_options(:all,:order => 'name')
    return if handle_module_paragraph_update(@options)
  end
  
  class InstructorDetailOptions < HashModel
    default_options :event_page_id => nil, :instructor_id => nil, :list_page_id => nil, :events_credit_type_id => nil
    
    integer_options :event_page_id, :instructor_id, :list_page_id, :events_credit_type_id

    page_options :event_page_id, :list_page_id
  end
  
  
  def repeat_list
   @options = EventListOptions.new(params[:repeat_list] || paragraph.data)
      
    return if handle_module_paragraph_update(@options)

    @per_page = (1..50).to_a
    @pages = SiteNode.page_options()
  end
  
  class EventRepeatListOptions < HashModel
    default_options :events_detail_page_id => nil, :detail_page_id => nil, :per_page => 10, :days_display => 10, :instructor_page_id => nil,  :events_credit_type_id => nil 
    
    integer_options :events_detail_page_id, :instructor_page_id, :events_credit_type_id 

    page_options :events_detail_page_id, :detail_page_id, :instructor_page_id
  end
  
end
