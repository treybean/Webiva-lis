require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe NotificationMessage do

  reset_domain_tables :notification_message, :notification_type, :notification_message_tag, :notification_message_user, :end_user, :end_user_tag, :content_model

  it "should require a message and a user" do
    @msg = NotificationMessage.new
    @msg.should have(1).error_on(:notification_type_id)
    @msg.should have(1).error_on(:view_type)

    @msg = NotificationMessage.create :notification_type_id => 1, :view_type => 'once'
    @msg.id.should_not be_nil
    @msg.has_tags.should be_false
    @msg.created_at.should_not be_nil
  end

  it "should be able to set tags" do
    @t1 = Tag.create :name => 'Tag1'
    @t2 = Tag.create :name => 'Tag2'
    @t3 = Tag.create :name => 'Tag3'
    @t4 = Tag.create :name => 'Tag4'
    @t5 = Tag.create :name => 'Tag5'

    assert_difference 'NotificationMessage.count', 1 do
      assert_difference 'NotificationMessageTag.count', 5 do
        @msg = NotificationMessage.create :notification_type_id => 1, :view_type => 'once', :tags => [@t1.id, @t2.id, @t3.id, @t4.id, @t5.id]
      end
    end

    @msg.reload
    assert_difference 'NotificationMessageTag.count', -1 do
      @msg.update_attributes :tags => [@t1.id, @t2.id, @t3.id, @t4.id]
    end

    @msg.reload
    assert_difference 'NotificationMessageTag.count', -3 do
      @msg.update_attributes :tags => [@t1.id]
    end

    @msg.reload
    assert_difference 'NotificationMessageTag.count', 1 do
      @msg.update_attributes :tags => [@t2.id, @t5.id]
    end

    @msg.reload
    @msg.tags.detect { |t| t.id == @t1.id }.should be_nil
    @msg.tags.detect { |t| t.id == @t2.id }.should == @t2
    @msg.tags.detect { |t| t.id == @t3.id }.should be_nil
    @msg.tags.detect { |t| t.id == @t4.id }.should be_nil
    @msg.tags.detect { |t| t.id == @t5.id }.should == @t5
  end

  describe 'Fetching User Messages' do
    before(:each) do
      @user1 = EndUser.push_target('user1@test.dev')
      @user1.tag 'New,Messaged,User1'
      @user2 = EndUser.push_target('user2@test.dev')
      @user2.tag 'New,User2'
      @user3 = EndUser.push_target('user3@test.dev')

      @user1.reload
      @user2.reload
      @user3.reload

      @type = NotificationType.create :name => 'notification type', :content_model_id => 1
    end

    it "should find messages for everyone" do
      @msg1 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1
      @msg2 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :expires_at => 5.hours.since
      @msg3 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.ago
      @msg4 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.since
      @msg5 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :expires_at => 5.hours.ago
      @msg6 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.ago, :expires_at => 5.hours.since
      @msg7 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.since, :expires_at => 6.hours.since
      @msg8 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 6.hours.ago, :expires_at => 5.hours.ago

      @messages = NotificationMessage.fetch_user_messages @user1, @type.id
      @messages.size.should == 4
      @messages.detect { |m| m.id == @msg1.id }.should == @msg1
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should == @msg3
      @messages.detect { |m| m.id == @msg4.id }.should be_nil
      @messages.detect { |m| m.id == @msg5.id }.should be_nil
      @messages.detect { |m| m.id == @msg6.id }.should == @msg6
      @messages.detect { |m| m.id == @msg7.id }.should be_nil
      @messages.detect { |m| m.id == @msg8.id }.should be_nil

      @messages = NotificationMessage.fetch_user_messages @user2, @type.id
      @messages.size.should == 4
      @messages.detect { |m| m.id == @msg1.id }.should == @msg1
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should == @msg3
      @messages.detect { |m| m.id == @msg4.id }.should be_nil
      @messages.detect { |m| m.id == @msg5.id }.should be_nil
      @messages.detect { |m| m.id == @msg6.id }.should == @msg6
      @messages.detect { |m| m.id == @msg7.id }.should be_nil
      @messages.detect { |m| m.id == @msg8.id }.should be_nil

      @messages = NotificationMessage.fetch_user_messages @user3, @type.id
      @messages.size.should == 4
      @messages.detect { |m| m.id == @msg1.id }.should == @msg1
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should == @msg3
      @messages.detect { |m| m.id == @msg4.id }.should be_nil
      @messages.detect { |m| m.id == @msg5.id }.should be_nil
      @messages.detect { |m| m.id == @msg6.id }.should == @msg6
      @messages.detect { |m| m.id == @msg7.id }.should be_nil
      @messages.detect { |m| m.id == @msg8.id }.should be_nil
    end

    it "should find user specific messages" do
      @msg1 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :end_user_id => @user1.id
      @msg2 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :expires_at => 5.hours.since
      @msg3 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :end_user_id => @user2.id
      @msg4 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :end_user_id => @user3.id

      @messages = NotificationMessage.fetch_user_messages @user1, @type.id
      @messages.size.should == 2
      @messages.detect { |m| m.id == @msg1.id }.should == @msg1
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should be_nil
      @messages.detect { |m| m.id == @msg4.id }.should be_nil

      @messages = NotificationMessage.fetch_user_messages @user2, @type.id
      @messages.size.should == 2
      @messages.detect { |m| m.id == @msg1.id }.should be_nil
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should == @msg3
      @messages.detect { |m| m.id == @msg4.id }.should be_nil

      @messages = NotificationMessage.fetch_user_messages @user3, @type.id
      @messages.size.should == 2
      @messages.detect { |m| m.id == @msg1.id }.should be_nil
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should be_nil
      @messages.detect { |m| m.id == @msg4.id }.should == @msg4
    end

    it "should find messages for users with specific tags" do
      @new_tag = Tag.first :conditions => {:name => "New"}
      @messaged_tag = Tag.first :conditions => {:name => "Messaged"}
      @user1_tag = Tag.first :conditions => {:name => "User1"}
      @user2_tag = Tag.first :conditions => {:name => "User2"}

      @msg1 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :end_user_id => @user1.id
      @msg2 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :expires_at => 5.hours.since
      @msg3 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :tags => [@new_tag.id]
      @msg4 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :tags => [@messaged_tag.id]
      @msg5 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :tags => [@user1_tag.id]
      @msg6 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :tags => [@user2_tag.id]
      @msg7 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :tags => [@user1_tag.id, @user2_tag.id]

      @messages = NotificationMessage.fetch_user_messages @user1, @type.id
      @messages.size.should == 6
      @messages.detect { |m| m.id == @msg1.id }.should == @msg1
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should == @msg3
      @messages.detect { |m| m.id == @msg4.id }.should == @msg4
      @messages.detect { |m| m.id == @msg5.id }.should == @msg5
      @messages.detect { |m| m.id == @msg6.id }.should be_nil
      @messages.detect { |m| m.id == @msg7.id }.should == @msg7

      @messages = NotificationMessage.fetch_user_messages @user2, @type.id
      @messages.size.should == 4
      @messages.detect { |m| m.id == @msg1.id }.should be_nil
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should == @msg3
      @messages.detect { |m| m.id == @msg4.id }.should be_nil
      @messages.detect { |m| m.id == @msg5.id }.should be_nil
      @messages.detect { |m| m.id == @msg6.id }.should == @msg6
      @messages.detect { |m| m.id == @msg7.id }.should == @msg7

      @messages = NotificationMessage.fetch_user_messages @user3, @type.id
      @messages.size.should == 1
      @messages.detect { |m| m.id == @msg1.id }.should be_nil
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
      @messages.detect { |m| m.id == @msg3.id }.should be_nil
      @messages.detect { |m| m.id == @msg4.id }.should be_nil
      @messages.detect { |m| m.id == @msg5.id }.should be_nil
      @messages.detect { |m| m.id == @msg6.id }.should be_nil
      @messages.detect { |m| m.id == @msg7.id }.should be_nil
    end

    it "should not display cleared messages by users" do
      @msg1 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1
      @msg2 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1

      assert_difference 'NotificationMessageUser.count', 1 do
        @msg1.clear @user1
      end

      @messages = NotificationMessage.fetch_user_messages @user1, @type.id
      @messages.size.should == 1
      @messages.detect { |m| m.id == @msg1.id }.should be_nil
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2

      @messages = NotificationMessage.fetch_user_messages @user2, @type.id
      @messages.size.should == 2
      @messages.detect { |m| m.id == @msg1.id }.should == @msg1
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2

      @messages = NotificationMessage.fetch_user_messages @user3, @type.id
      @messages.size.should == 2
      @messages.detect { |m| m.id == @msg1.id }.should == @msg1
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2

      @msg1.reload
      assert_difference 'NotificationMessageUser.count', 0 do
        @msg1.unclear @user1
      end
     
      @messages = NotificationMessage.fetch_user_messages @user1, @type.id
      @messages.size.should == 2
      @messages.detect { |m| m.id == @msg1.id }.should == @msg1
      @messages.detect { |m| m.id == @msg2.id }.should == @msg2
    end

    it "should expires old messages" do
      @msg1 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1
      @msg2 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :expires_at => 5.hours.since
      @msg3 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.ago
      @msg4 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.since
      @msg5 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :expires_at => 5.hours.ago
      @msg6 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.ago, :expires_at => 5.hours.since
      @msg7 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.since, :expires_at => 6.hours.since
      @msg8 = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 6.hours.ago, :expires_at => 5.hours.ago

      @msg1.expired.should be_false
      @msg2.expired.should be_false
      @msg3.expired.should be_false
      @msg4.expired.should be_false
      @msg5.expired.should be_true
      @msg6.expired.should be_false
      @msg7.expired.should be_false
      @msg8.expired.should be_true

      NotificationMessage.update_all 'expired = 0'

      @msg1.reload
      @msg1.expired.should be_false
      @msg5.reload
      @msg5.expired.should be_false
      @msg8.reload
      @msg8.expired.should be_false

      NotificationMessage.expire_messages

      @msg1.reload
      @msg1.expired.should be_false
      @msg5.reload
      @msg5.expired.should be_true
      @msg8.reload
      @msg8.expired.should be_true
    end
  end

  it "should be able to tell if a message is active" do
    @type = NotificationType.create :name => 'notification type', :content_model_id => 1

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1
    @msg.active?.should be_true

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.ago
    @msg.active?.should be_true

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :expires_at => 5.hours.since
    @msg.active?.should be_true

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.ago, :expires_at => 5.hours.since
    @msg.active?.should be_true

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.since
    @msg.active?.should be_false

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :expires_at => 5.hours.ago
    @msg.active?.should be_false

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :starts_at => 5.hours.since, :expires_at => 6.hours.since
    @msg.active?.should be_false
  end

  it "should be able to tell if a message is for everyone" do
    @type = NotificationType.create :name => 'notification type', :content_model_id => 1
    @user = EndUser.push_target 'test@test.dev'
    @user.tag 'Tag'
    @user.reload
    @tag = Tag.first :conditions => {:name => "Tag"}

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1
    @msg.everyone?.should be_true

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :end_user_id => @user.id
    @msg.everyone?.should be_false

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :tags => [@tag.id]
    @msg.everyone?.should be_false

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1, :end_user_id => @user.id, :tags => [@tag.id]
    @msg.everyone?.should be_false
  end

  it "should be able to push message user" do
    @type = NotificationType.create :name => 'notification type', :content_model_id => 1
    @user = EndUser.push_target 'test@test.dev'

    @msg = @type.notification_messages.create :view_type => 'once', :data_model_id => 1
    @msg.push_message_user(@user).should_not be_nil
    @msg.cleared?(@user).should be_false
  end
end
