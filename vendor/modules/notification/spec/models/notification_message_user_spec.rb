require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe NotificationMessageUser do

  reset_domain_tables :notification_message_user

  it "should require a message and a user" do
    @seen = NotificationMessageUser.new
    @seen.should have(1).error_on(:end_user_id)
    @seen.should have(1).error_on(:notification_message_id)

    @seen = NotificationMessageUser.create :end_user_id => 1, :notification_message_id => 1
    @seen.id.should_not be_nil
    @seen.cleared.should be_false
  end
end
