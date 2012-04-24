require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../forum_test_helper'

describe ForumSubscription do

  include ForumTestHelper

  reset_domain_tables :forum_forums,:forum_posts,:forum_categories,:forum_topics,:end_users,:forum_subscriptions

  it 'Initial test data validation' do
    @user = create_end_user
    @user.save.should be_true
    @cat = create_forum_category
    @cat.save.should be_true
    @forum = create_forum_forum @cat
    @forum.save.should be_true
    @topic = create_forum_topic_with_end_user( @forum, @user )
    @topic.save.should be_true
    @forum.reload
    @forum.forum_topics.size.should == 1
    @post = create_forum_post_with_end_user(@topic, @user)
    @post.save.should be_true
    @topic.reload
    @topic.forum_posts.size.should == 1
  end

  describe 'Detailed forum subscription testing' do

    before(:each) do
      @user = create_end_user
      @user.save
      @cat = create_forum_category
      @cat.save
      @forum = create_forum_forum @cat
      @forum.save
      @topic = create_forum_topic_with_end_user( @forum, @user )
      @topic.save
      @forum.reload
      @post = create_forum_post_with_end_user(@topic, @user)
      @post.save
      @topic.reload
    end

    it "should require a end_user_id, forum_forum_id and forum_topic_id" do
      @subscription = ForumSubscription.new()

      @subscription.valid?

      @subscription.should have(1).errors_on(:end_user_id)
      @subscription.should have(1).errors_on(:forum_topic_id)
      @subscription.should have(1).errors_on(:forum_forum_id)
    end

    it "should create a valid subscription from topic.build_subscription" do
      @subscription = @topic.build_subscription @user
      @subscription.save.should be_true

      @subscription = @topic.build_subscription @user
      @subscription.save.should_not be_true
    end
  end
end
