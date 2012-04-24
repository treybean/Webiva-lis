require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe NotificationMessageTag do

  reset_domain_tables :notification_message_tag

  it "should require a message and a user" do
    @tag = NotificationMessageTag.new
    @tag.should have(1).error_on(:tag_id)
    @tag.should have(1).error_on(:notification_message_id)

    @tag = NotificationMessageTag.create :tag_id => 1, :notification_message_id => 1
    @tag.id.should_not be_nil
  end
end
