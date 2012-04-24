
class Notification::PageRenderer < ParagraphRenderer

  features '/notification/page_feature'

  paragraph :notifications, :ajax => true

  def notifications
    @options = paragraph_options(:notifications)
    @type = @options.notification_type
    return render_paragraph :text => (editor? ? 'Please configure paragraph' : '') unless @type

    if request.post? && params[:message] && myself.id && ! editor?
      @notification = NotificationMessage.find_by_id params[:message]
      @notification.clear myself
    end

    require_js('prototype') unless ajax?

    @notifications = []
    if @type
      @notifications = NotificationMessage.fetch_user_messages(myself, @type.id, :limit => @options.limit) if myself.id
      @notifications = NotificationMessage.for_type(@type.id).find(:all, :order => 'created_at DESC', :limit => 5) if editor? && @notifications.empty?
      @notifications.each { |n| n.view_type == 'once' ? n.clear(myself) : n.push_message_user(myself) } unless editor?
    end

    render_paragraph :feature => :notification_page_notifications
  end
end
