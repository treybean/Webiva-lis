
class Notification::ManageUserController < ModuleController
  
  permit 'notification_manage'

  component_info 'Notification'
  
  def self.members_view_handler_info
    { 
      :name => 'Notifications',
      :controller => '/notification/manage_user',
      :action => 'view'
    }
   end  
  
  # need to include
  include ActiveTable::Controller
  active_table :user_messages_table,
               NotificationMessage, 
               [ :check,
                 hdr(:static, 'Name'),
                 hdr(:static, 'Seen'),
                 hdr(:static, 'Active'),
                 :expired,
                 :created_at
               ]

  public

  def display_user_messages_table(display=true)
    @user ||= EndUser.find params[:path][0]
    @tab ||= params[:tab]
    @tbl = user_messages_table_generate( params, :conditions => ['notification_messages.end_user_id = ? || notification_message_users.end_user_id = ?', @user.id, @user.id], :include => [:notification_message_users], :order => 'created_at DESC')

    @seen_msgs = NotificationMessageUser.find(:all, :select => 'notification_message_id', :conditions => {:end_user_id => @user.id, :notification_message_id => @tbl.data.collect(&:id)}).group_by(&:notification_message_id)

    render :partial => 'user_messages_table' if display
  end

  def view
    @user = EndUser.find params[:path][0]
    @tab = params[:tab]
    display_user_messages_table false
    render :partial => 'view'
  end

  def notify
    @user = EndUser.find params[:path][0]
    @message = NotificationMessage.new
    @tab = params[:tab]

    @num_types = NotificationType.count

    if request.post?
      if params[:message]

        @message.notification_type_id = params[:message][:notification_type_id]

        @message.attributes = params[:message]
        @message.end_user_id = @user.id

        if params[:commit] && @message.save
          render :update do |page|
            page <<  'NotificationData.viewMessages();'
          end
          return
        end
      end
    elsif @message.notification_type.nil?
      type = NotificationType.first :conditions => {:default => true}
      type ||= NotificationType.first
      @message.notification_type_id = type.id if type
    end

    render :partial => 'notify'
  end
end
