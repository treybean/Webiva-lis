
class Notification::AdminController < ModuleController

  component_info 'Notification', :description => 'Notification support', :access => :public
                              
  # Register a handler feature
  register_permission_category :notification, "Notification", "Permissions related to Notification"
  
  register_permissions :notification, [[:manage, 'Manage Notification', 'Manage Notification'],
                                       [:config, 'Configure Notification', 'Configure Notification']
                                      ]

  content_model :notification

  permit 'notification_config'

  register_cron :expire_messages, "NotificationMessage", :hours => [1]

  register_handler :members, :view,  "Notification::ManageUserController"
  register_handler :user_segment, :fields, 'NotificationMessageUserSegmentField'

  public

  def self.get_notification_info
    [
      {:name => 'Notifications', :url => {:controller => '/notification/manage'}, :permission => 'notification_manage', :icon => 'icons/content/feedback.gif'}
    ]
  end

end
