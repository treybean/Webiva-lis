require  File.expand_path(File.dirname(__FILE__)) + "/../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../../../../spec/content_spec_helper"

module NotificationSpecHelper
  include ContentSpecHelper

  def create_content_model
    @content_model ||= create_dummy_fields(create_spec_test_content_model)
  end

  def create_notification_type(cm=nil)
    cm ||= create_content_model
    @type ||= NotificationType.create :content_model_id => cm.id, :name => cm.name
  end

  def create_notification_message(opts, type=nil)
    opts[:view_type] ||= 'always'
    type ||= create_notification_type
    msg = type.notification_messages.new
    msg.attributes = opts
    msg.save
    msg
  end
end
