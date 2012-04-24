
class NotificationType < DomainModel
  has_many :notification_messages, :dependent => :destroy
  belongs_to :content_model

  validates_presence_of :name
  validates_presence_of :content_model_id

  content_node_type :notification, "NotificationMessage"

  def content_admin_url(notification_message_id)
    {:controller => '/notification/manage', :action => 'message', :path => [notification_message_id], :title => 'Edit Notification'.t}
  end

  def content_type_name; 'Notification'; end
end
