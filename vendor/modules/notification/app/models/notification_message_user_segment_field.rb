
class NotificationMessageUserSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'Notifications',
      :domain_model_class => NotificationMessageUser
    }
  end

  class NotificationType < UserSegment::FieldType
    def self.select_options
      NotificationMessage.select_options :order => 'created_at DESC'
    end

    register_operation :is, [['Notification', :model, {:class => NotificationMessageUserSegmentField::NotificationType}]]

    def self.is(cls, group_field, field, source)
      cls.scoped(:conditions => ["#{field} = ?", source])
    end
  end

  register_field :num_notifications, UserSegment::CoreType::CountType, :field => :end_user_id, :name => '# Notifications Seen', :display_method => 'count', :sort_method => 'count', :sortable => true
  register_field :notification, NotificationMessageUserSegmentField::NotificationType, :field => :notification_message_id, :name => 'Notification', :search_only => true
  register_field :notification_cleared, UserSegment::CoreType::BooleanType, :field => :cleared, :name => 'Notification Cleared', :search_only => true

  def self.sort_scope(order_by, direction)
    info = UserSegment::FieldHandler.sortable_fields[order_by.to_sym]
    sort_method = info[:sort_method]
    field = info[:field]

    if sort_method
      NotificationMessageUser.scoped(:select => "end_user_id, #{sort_method}(#{field}) as #{field}_#{sort_method}", :group => :end_user_id, :order => "#{field}_#{sort_method} #{direction}")
    else
      NotificationMessageUser.scoped(:order => "#{field} #{direction}")
    end
  end

  def self.get_handler_data(ids, fields)
    NotificationMessageUser.find(:all, :conditions => {:end_user_id => ids}).group_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    UserSegment::FieldType.field_output(user, handler_data, field)
  end
end

