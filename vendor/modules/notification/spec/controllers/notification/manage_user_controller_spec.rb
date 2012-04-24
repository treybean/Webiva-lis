require  File.expand_path(File.dirname(__FILE__)) + "/../../notification_spec_helper"

describe Notification::ManageUserController do
  include NotificationSpecHelper

  reset_domain_tables :content_model, :content_model_field, :notification_message, :notification_type, :notification_message_user, :notification_message_tag, :end_user, :tag, :end_user_tag

  describe 'CM Tests' do
    before(:each) do
      mock_editor
      @msg = create_notification_message :data_model => {'string_field' => 'test'}, :end_user_id => @myself.id
    end

    it "should display the view page" do
      get 'view', :path => [@myself.id], :tab => 1
    end

    it "should handle user messages table list" do
      controller.should handle_active_table(:user_messages_table) do |args|
        args ||= {}
        args[:path] = [@myself.id]
        args[:tab] = 1
        post 'display_user_messages_table', args
      end
    end

    it "should display the notify page" do
      get 'notify', :path => [@myself.id], :tab => 1
    end

    it "should create a new notification for the user" do
      assert_difference 'NotificationMessage.count', 1 do
        post 'notify', :path => [@myself.id], :tab => 1, :commit => 1, :message => {:notification_type_id => @type.id, :view_type => 'always', :data_model => {:string_field => 'new test'}}
      end

      msg = NotificationMessage.last
      msg.excerpt.should == 'new test'
      msg.end_user_id.should == @myself.id
    end
  end
end
