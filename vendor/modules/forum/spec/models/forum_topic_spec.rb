require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../forum_test_helper'

describe ForumTopic do

  include ForumTestHelper

  reset_domain_tables :forum_forums,:forum_posts,:forum_categories,:forum_topics,:end_users

  it 'Initial test data validation' do
    @user = create_end_user
    @user.save.should be_true
    @cat = create_forum_category
    @cat.save.should be_true
    @forum = create_forum_forum @cat
    @forum.save.should be_true
  end

  describe 'Detailed forum topic testing' do

    before(:each) do
      @user = create_end_user
      @user.save
      @cat = create_forum_category
      @cat.save
      @forum = create_forum_forum @cat
      @forum.save
    end

    it "should require a subject, posted_by and forum_forum_id" do
      @topic = ForumTopic.new()

      @topic.valid?

      @topic.should have(1).errors_on(:subject)
      @topic.should have(1).errors_on(:posted_by)
      @topic.should have(1).errors_on(:forum_forum_id)
    end

    it "should set posted_by to end_user.username" do
      @topic = @forum.forum_topics.build :subject => 'test subject', :end_user => @user
      @topic.save.should be_true
      @topic.posted_by.should == (@user.first_name + ' ' + @user.last_name)
    end

    it "should increment forum_topics_count" do
      @topic = @forum.forum_topics.build :subject => 'test subject', :posted_by => 'Test User'
      @topic.save.should be_true
      @forum.reload
      @forum.forum_topics.size.should == 1

      @topic = @forum.forum_topics.build :subject => 'test subject', :end_user => @user
      @topic.save.should be_true
      @forum.reload
      @forum.forum_topics.size.should == 2
    end

    it "should be able to set a topic as sticky" do
      @topic = @forum.forum_topics.build :subject => 'test subject', :end_user => @user, :sticky => 1
      @topic.save.should be_true
      @forum.forum_topics.sticky_topics.count.should == 1
    end

    it "should be able to connect to a sperate piece of content" do
      @topic = @forum.forum_topics.build :subject => 'test subject', :end_user => @user, :sticky => 1, :content => @user
      @topic.save.should be_true
      @forum.forum_topics.sticky_topics.count.should == 1
      @topic.content_type.should == 'EndUser'
      @topic.content_id.should == @user.id
    end
  end
end
