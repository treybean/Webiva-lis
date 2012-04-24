require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../forum_test_helper'

describe ForumPost do

  include ForumTestHelper

  reset_domain_tables :forum_forums,:forum_posts,:forum_categories,:forum_topics,:end_users

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
  end

  describe 'Detailed forum post testing' do

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
    end

    it "should require a body, posted_by and forum_forum_id" do
      @post = ForumPost.new()

      @post.valid?

      @post.should have(1).errors_on(:body)
      @post.should have(1).errors_on(:subject)
      @post.should have(1).errors_on(:forum_forum_id)
    end

    it "should set posted_by to end_user.username" do
      @post = @topic.build_post :body => 'test post', :end_user => @user
      @post.save.should be_true
      @post.posted_by.should == (@user.first_name + ' ' + @user.last_name)
    end

    it "should increment forum_posts_count" do
      @post = @topic.build_post :body => 'test post', :end_user => @user
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 1

      @post = @topic.build_post :body => 'test post', :posted_by => 'Test User2'
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 2
    end

    it "should be able to fetch first post" do
      @first_post = @topic.build_post :body => 'test post', :end_user => @user
      @first_post.save.should be_true

      @post = @topic.build_post :body => '2nd test post', :posted_by => 'user2'
      @post.save.should be_true

      @topic.first_post.should == @first_post
    end

    it "should be able to fetch last post" do
      @post = @topic.build_post :body => 'test post', :end_user => @user
      @post.save.should be_true
      @topic.reload
      @topic.last_post.should == @post

      @post = @topic.build_post :body => '2nd test post', :posted_by => 'user2'
      @post.save.should be_true
      @topic.reload
      @topic.last_post.should == @post
    end

    it "should increment forum_posts_count for approved posts only" do
      @post = create_forum_post_with_end_user(@topic, @user)
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 1
      @topic.activity_count.should == 1

      @post = create_forum_post(@topic, 'test post', {:posted_by => 'Test User 2'})
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 2
      @topic.activity_count.should == 2

      @post.update_attributes :approved => false
      @topic.reload
      @topic.forum_posts.size.should == 1
      @topic.activity_count.should == 2

      @topic.updated_at = 3.days.ago
      @topic.recent_activity_count.should == 0
    end

    it "should decrement forum_posts_count for destroy posts" do
      @post = create_forum_post_with_end_user(@topic, @user)
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 1
      @topic.activity_count.should == 1

      @post = create_forum_post(@topic, 'test post to destroy', {:posted_by => 'Test User 3'})
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 2
      @topic.activity_count.should == 2

      @post.destroy
      @topic.reload
      @topic.forum_posts.size.should == 1
      @topic.activity_count.should == 2
    end

    it "should increment activity_count for new posts in last 2 days" do
      @post = create_forum_post_with_end_user(@topic, @user)
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 1
      @topic.activity_count.should == 1

      @post.update_attributes :posted_at => 3.days.ago

      @post = create_forum_post(@topic, 'test post', {:posted_by => 'Test User2'})
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 2
      @topic.activity_count.should == 1

      @post.update_attributes :posted_at => 1.days.ago

      @post = create_forum_post(@topic, 'test post', {:posted_by => 'Test User3'})
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 3
      @topic.activity_count.should == 2
    end

    it "should only update edited_at if body changes" do
      body = 'test post'
      @post = create_forum_post(@topic, body, {:posted_by => 'Test User3'})
      @post.save.should be_true
      @post.edited_at.should == nil
      @topic.reload

      @post.update_attributes :body => body
      @post.edited_at.should == nil

      @post.update_attributes :body => 'updated test post'
      @post.edited_at.should_not == nil
    end

    it "should update moderated_by_id and moderated_at" do
      @post = create_forum_post_with_end_user(@topic, @user)
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 1
      @topic.activity_count.should == 1

      @post.moderated_by.should == nil
      @post.moderated_at.should == nil

      @moderator = create_end_user('moderator@test.dev', {})
      @post.moderated @moderator
      @post.save

      @post.moderated_by.should == @moderator
      @post.moderated_by_id.should == @moderator.id
      @post.moderated_at.should_not == nil
    end

    it "should destroy post if forum category is destroyed" do
      @post = create_forum_post_with_end_user(@topic, @user)
      @post.save.should be_true
      @topic.reload
      @topic.forum_posts.size.should == 1
      @topic.activity_count.should == 1

      @cat.destroy

      @destroy_cat = ForumCategory.find_by_id(@cat)
      @destroy_cat.should be_nil

      @destroy_forum = ForumForum.find_by_id(@forum)
      @destroy_forum.should be_nil

      @destroy_topic = ForumTopic.find_by_id(@topic)
      @destroy_topic.should be_nil

      @destroy_post = ForumPost.find_by_id(@post)
      @destroy_post.should be_nil
    end

    it "should be able to create a topic from the first post" do
      @post = ForumPost.new :subject => 'Test Subject', :body => 'First Post', :end_user => @user, :forum_forum => @forum
      @post.save.should be_true
      @post.forum_topic.should_not be_nil
      @forum.reload
      @forum.forum_topics.size.should == 2
      @post.forum_topic.should_not == @topic
    end
  end
end
