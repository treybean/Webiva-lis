require  File.expand_path(File.dirname(__FILE__)) + "/../../notification_spec_helper"

describe Notification::PageRenderer, :type => :controller do
  include NotificationSpecHelper
  controller_name :page
  integrate_views

  reset_domain_tables :content_model, :content_model_field, :notification_message, :notification_type, :notification_message_user, :notification_message_tag, :end_user, :tag, :end_user_tag

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/notification/page/' + paragraph, options, inputs)
  end

  describe "CM Tests" do
    before(:each) do
      @msg = create_notification_message :data_model => {'string_field' => 'test'}
    end

    it "should render the notifications paragraph" do
      @rnd = generate_page_renderer('notifications', {:notification_type_id => @type.id})
      assert_difference 'NotificationMessageUser.count', 0 do
        renderer_get @rnd
      end
    end

    it "should render the notifications paragraph" do
      mock_user
      @rnd = generate_page_renderer('notifications', {:notification_type_id => @type.id})

      assert_difference 'NotificationMessageUser.count', 1 do
        renderer_get @rnd
      end

      msg_user = NotificationMessageUser.last
      msg_user.end_user_id.should == @myself.id
      msg_user.notification_message_id.should == @msg.id
      msg_user.cleared.should be_false
    end

    describe "Ajax Notifications Tests" do
      before(:each) do
        mock_user

        @msg = create_notification_message :view_type => 'clear', :data_model => {'string_field' => 'test'}
        @rnd = generate_page_renderer('notifications', {:notification_type_id => @type.id})
        @rnd.should_receive(:ajax?).any_number_of_times.and_return(true)

        @msg_user = NotificationMessageUser.create :notification_message_id => @msg.id, :end_user_id => @myself.id
      end

      it "should clear out the message" do
        @msg_user.id.should_not be_nil
        @msg_user.cleared.should be_false
        assert_difference 'NotificationMessageUser.count', 1 do
          renderer_post @rnd, :message => @msg.id
        end
        @msg_user.reload
        @msg_user.cleared.should be_true
      end
    end

    describe "One Time View Notifications" do
      before(:each) do
        mock_user
        @msg = create_notification_message :view_type => 'once', :data_model => {'string_field' => 'test'}
        @rnd = generate_page_renderer('notifications', {:notification_type_id => @type.id})
      end

      it "should clear out the message" do
        assert_difference 'NotificationMessageUser.count', 2 do
          renderer_post @rnd, :message => @msg.id
        end
        @msg_user = NotificationMessageUser.first :conditions => {:end_user_id => @myself.id, :notification_message_id => @msg.id}
        @msg_user.cleared.should be_true
      end
    end
  end
end
