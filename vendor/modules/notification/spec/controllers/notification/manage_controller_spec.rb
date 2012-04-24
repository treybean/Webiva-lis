require  File.expand_path(File.dirname(__FILE__)) + "/../../notification_spec_helper"

describe Notification::ManageController do
  include NotificationSpecHelper

  reset_domain_tables :content_model, :content_model_field, :notification_message, :notification_type, :notification_message_user, :notification_message_tag, :end_user, :tag, :end_user_tag

  describe "CM Tests" do
    before(:each) do
      mock_editor
      @msg = create_notification_message :data_model => {'string_field' => 'test'}
    end

    it "should render the index page" do
      get 'index'
    end

    it "should handle messages table list" do
      controller.should handle_active_table(:messages_table) do |args|
        post 'display_messages_table', args
      end
    end

    it "should be able to delete a message" do
      assert_difference 'NotificationMessage.count', -1 do
        post 'display_messages_table', :table_action => 'delete', :message => {@msg.id => @msg.id}
      end
      NotificationMessage.find_by_id(@msg.id).should be_nil
    end

    it "should render the types page" do
      get 'types'
    end

    it "should handle types table list" do
      controller.should handle_active_table(:types_table) do |args|
        post 'display_types_table', args
      end
    end

    it "should be able to delete a message type" do
      assert_difference 'NotificationType.count', -1 do
        assert_difference 'NotificationMessage.count', -1 do
          post 'display_types_table', :table_action => 'delete', :type => {@type.id => @type.id}
        end
      end
    end

    it "should be able to set default message type" do
      @type.default.should be_false
      post 'display_types_table', :table_action => 'default', :type => {@type.id => @type.id}
      @type.reload
      @type.default.should be_true
    end

    it "should render message_type form" do
      get 'message_type', :path => []
    end

    it "should be able to create a message type" do
      assert_difference 'NotificationType.count', 1 do
        post 'message_type', :path => [], :type => {:content_model_id => @content_model.id}
      end
      new_type = NotificationType.last
      new_type.name.should == @content_model.name
    end

    it "should be able to edit a message type" do
      assert_difference 'NotificationType.count', 0 do
        post 'message_type', :path => [@type.id], :type => {:content_model_id => @content_model.id, :name => 'New Type'}
      end

      @type.reload
      @type.name.should == 'New Type'
    end

    it "should render messages form" do
      get 'message', :path => []
    end

    it "should create a new message" do
      assert_difference 'NotificationMessage.count', 1 do
        post 'message', :path => [], :commit => 1, :message => {:view_type => 'always', :notification_type_id => @type.id, :data_model => {:string_field => 'new test'}}
      end

      msg = NotificationMessage.last
      msg.data_model.string_field.should == 'new test'
      msg.excerpt.should == 'new test'
      msg.everyone?.should be_true
      msg.active?.should be_true
      msg.expired.should be_false
    end
  end
end
