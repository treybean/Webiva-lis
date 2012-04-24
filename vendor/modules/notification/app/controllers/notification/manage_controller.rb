
class Notification::ManageController < ModuleController

  component_info 'Notification'

  cms_admin_paths 'content',
    'Notifications' => {:action => 'index'}

  # need to include 
  include ActiveTable::Controller
  active_table :messages_table,
               NotificationMessage, 
               [ :check,
                 hdr(:static, 'Name'),
                 hdr(:static, 'Type'),
                 :view_type,
                 hdr(:static, 'Active'),
                 :expired,
                 :starts_at,
                 :expires_at,
                 :created_at,
                 hdr(:static, 'User'),
                 hdr(:static, 'Tags')
               ]

  def display_messages_table(display=true)
    active_table_action 'message' do |act,ids|
      case act
      when 'delete': NotificationMessage.destroy(ids)
      end
    end

    @tbl = messages_table_generate( params, :order => 'created_at DESC', :include => [:notification_type, :notification_message_tags])
    render :partial => 'messages_table' if display
  end

  def index
    cms_page_path ['Content'], 'Notifications'
    display_messages_table false
  end

  def message
    @message = NotificationMessage.find_by_id(params[:path][0]) || NotificationMessage.new(:notification_type_id => params[:type_id])
    cms_page_path ['Content', 'Notifications'], (@message.id ? 'Edit %s' / @message.name : 'Create Notification')

    @num_types = NotificationType.count
    return redirect_to(:action => 'message_type') if @num_types == 0

    if request.post?
      if params[:message]
        params[:message].delete(:end_user)

        @message.notification_type_id = params[:message][:notification_type_id]
        if params[:message][:end_user_id].blank?
          params[:message].delete(:end_user_id)
        end

        @message.attributes = params[:message]

        if params[:commit] && @message.save
          redirect_to :action => 'index'
        end
      end
    elsif @message.notification_type.nil?
      type = NotificationType.first :conditions => {:default => true}
      type ||= NotificationType.first
      @message.notification_type_id = type.id if type
    end

    render :partial => 'message_form' if request.xhr?
  end

  def message_type
    @type = NotificationType.find_by_id(params[:path][0]) || NotificationType.new(:default => false)
    cms_page_path ['Content', 'Notifications'], (@type.id ? 'Edit %s' / @type.name : 'Create Notification Type')

    if request.post?
      @type.attributes = params[:type] if params[:type]
      @type.name = @type.content_model.name if @type.name.blank? && @type.content_model

      if @type.save
        redirect_to :action => 'message', :type_id => @type.id
      end
    end
  end

  active_table :types_table,
               NotificationType, 
               [ :check,
                 :name,
                 hdr(:static, 'Default'),
                 hdr(:static, 'num_messages', :label => '# Messages')
               ]

  def display_types_table(display=true)
    active_table_action 'type' do |act,ids|
      case act
      when 'delete'
        NotificationType.destroy(ids)
      when 'default'
        NotificationType.update_all '`default` = 0'
        @type = NotificationType.find ids[0]
        @type.update_attribute :default, 1
      end
    end

    @tbl = types_table_generate(params, :order => 'name')
    render :partial => 'types_table' if display
  end

  def types
    cms_page_path ['Content', 'Notifications'], 'Notification Types'
    display_types_table false
  end
end
