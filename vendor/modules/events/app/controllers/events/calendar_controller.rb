

class Events::CalendarController < ParagraphController

  editor_header 'Event Paragraphs'
  
  editor_for :month_list, :name => 'Targeted Event Calendar', :inputs => { :target => [[:target,'Event Target',:target ], [ :target_list, "Target list",:target_list]], :path => [ [:path,'Date',:path]] },:features => [:events_calendar_month_list ]
  editor_for :upcoming_list, :name => 'Targeted Upcoming Events', :features => [:events_calendar_upcoming_list ], :inputs => [[:target,'Event Target',:target ]],     :outputs => [ [ :mapped_events, 'Results Data', :map_callback ] ]
  
  editor_for :event_detail,  :name => 'Targeted Event Detail', :features => [:events_calendar_event_detail ], :inputs => { :target => [[:target,'Event Target',:target ]], :event_id => [[:event_id,"Event ID",:path ]] }

  class MonthListOptions < HashModel
    attributes :detail_page_id => nil, :overlay => true, :block_width => 80, :block_height => 90, :target_type => 'targeted'
    integer_options :detail_page_id
    boolean_options :overlay
    page_options :detail_page_id
  end
  
  class UpcomingListOptions < HashModel
    attributes :max_events => 10, :overlay => true, :detail_page_id => nil, :target_type => 'targeted', :popup_page_id => nil
    
    page_options :popup_page_id
    integer_options :detail_page_id
    boolean_options :overlay
  end
  
  class EventDetailOptions < HashModel
    attributes :message_page_id => nil, :text_page_id => nil, :personal_events => true, :include_location => false, :open_booking => true, :overlay => true
    
    boolean_options :personal_events, :include_location, :open_booking, :overlay
    
    integer_options :message_page_id, :text_page_id
    page_options :message_page_id, :text_page_id
  
  end

end
