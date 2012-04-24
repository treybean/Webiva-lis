require File.dirname(__FILE__) + "/../../../../../spec/spec_helper"

describe NotificationMessageUserSegmentField do
  reset_domain_tables :end_users, :notification_message_user

  before do
    DataCache.reset_local_cache
    test_activate_module('notification')
  end

  after do
    SiteModule.destroy_all
  end

  def create_notification(user)
    NotificationMessageUser.create :end_user_id => user.id, :notification_message_id => 2
  end

  before(:each) do
    @user1 = EndUser.push_target('test1@test.dev')
    @user2 = EndUser.push_target('test2@test.dev')
    @user3 = EndUser.push_target('test3@test.dev')
    create_notification(@user1)
    create_notification(@user2)
    create_notification(@user2)
  end

  it "should only have valid Shop::ShopOrder fields" do
    NotificationMessageUser.count.should == 3

    obj = NotificationMessageUserSegmentField.user_segment_fields_handler_info[:domain_model_class].new
    NotificationMessageUserSegmentField.user_segment_fields.each do |key, value|
      obj.has_attribute?(value[:field]).should be_true
      obj.respond_to?(value[:display_field]).should be_true
    end
  end

  it "can output field data" do
    handler_data = NotificationMessageUserSegmentField.get_handler_data([@user1.id, @user2.id], [:notification])

    NotificationMessageUserSegmentField.user_segment_fields.each do |key, value|
      next if value[:search_only]
      NotificationMessageUserSegmentField.field_output(@user1, handler_data, key)
    end
  end

  it "should be able to sort on sortable fields" do
    ids = [@user1.id, @user2.id]
    seg = UserSegment.create :name => 'Test', :segment_type => 'custom'
    seg.id.should_not be_nil
    seg.add_ids ids

    NotificationMessageUserSegmentField.user_segment_fields.each do |key, value|
      next unless value[:sortable]
      scope = NotificationMessageUserSegmentField.sort_scope(key.to_s, 'DESC')
      scope.should_not be_nil

      seg.order_by = key.to_s
      seg.sort_ids(ids).should be_true
      seg.status.should == 'finished'
      seg.end_user_ids.size.should == 2
    end
  end
end
