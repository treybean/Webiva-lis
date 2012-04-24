
class Notification::PageController < ParagraphController

  editor_header 'Notification Paragraphs'
  
  editor_for :notifications, :name => "Notifications", :feature => :notification_page_notifications

  class NotificationsOptions < HashModel
    attributes :notification_type_id => nil, :limit => 5

    integer_options :limit

    validates_presence_of :notification_type_id

    def notification_type_options
      NotificationType.select_options_with_nil
    end

    def notification_type
      @notification_type ||= NotificationType.find_by_id(self.notification_type_id)
    end

    options_form(
                 fld(:notification_type_id, :select, :options => :notification_type_options),
                 fld(:limit, :text_field)
                 )
  end
end
