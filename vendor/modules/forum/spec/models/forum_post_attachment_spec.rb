require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../forum_test_helper'

describe ForumPostAttachment do

  include ForumTestHelper

  reset_domain_tables :forum_forums,:forum_posts,:forum_categories,:forum_topics,:end_users,:forum_post_attachments

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

  describe 'Detailed forum post attachment testing' do

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

    it "should require a end_user_id, forum_post_id and domain_file_id" do
      @attachment = ForumPostAttachment.new()

      @attachment.valid?

      @attachment.should have(1).errors_on(:end_user_id)
      @attachment.should have(1).errors_on(:forum_post_id)
      @attachment.should have(1).errors_on(:domain_file_id)
    end
  end
end
