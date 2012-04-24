require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../forum_test_helper'

describe Forum::PostsController do

  include ForumTestHelper

  reset_domain_tables :end_user,:forum_forums,:forum_posts,:forum_categories,:forum_topics

  before(:each) do
    mock_editor

    @forum_category = create_forum_category
    @forum_category.save
    @forum = create_forum_forum @forum_category
    @forum.save
    @topic = create_forum_topic_with_end_user @forum, @myself
    @topic.save
  end

  it "should handle table list" do 
  
    # Test all the permutations of an active table
    controller.should handle_active_table(:post_table) do |args|
      args[:path] = [@forum_category.id, @forum.id, @topic.id]
      post 'post_table', args
    end
  end

  it "should be able to create posts" do

    assert_difference 'ForumPost.count', 1 do
      post 'post', :path => [@forum_category.id, @forum.id, @topic.id], :post => { :body => 'Test Post Body' }
      @post = ForumPost.find(:last)
      response.should redirect_to(:controller => '/forum/posts', :action => 'list', :path => [@forum_category.id, @forum.id, @topic.id])
    end
  end

  it "should be able to edit post" do

    @post = create_forum_post_with_end_user @topic, @myself, 'Change This Body'
    @post.save.should be_true

    assert_difference 'ForumPost.count', 0 do
      post 'post', :path => [@forum_category.id, @forum.id, @topic.id, @post.id], :post => { :body => 'Test Post Body' }
      response.should redirect_to(:controller => '/forum/posts', :action => 'list', :path => [@forum_category.id, @forum.id, @topic.id])
      @post.reload
      @post.body.should == 'Test Post Body'
    end
  end

  it "should handle delete post" do 
  
    @post = create_forum_post_with_end_user @topic, @myself, 'Change This Body'
    @post.save.should be_true
    @topic.reload

    assert_difference '@topic.forum_posts_count', -1 do
      post 'post_table', :path => [@forum_category.id, @forum.id, @topic.id], :table_action => 'delete', :post => {@post.id => @post.id}
      @topic.reload
    end
  end

  it "should handle approving a post" do 
  
    @post = create_forum_post_with_end_user @topic, @myself, 'Change This Body', :approved => false
    @post.save.should be_true
    @topic.reload

    assert_difference '@topic.forum_posts_count', 1 do
      post 'post_table', :path => [@forum_category.id, @forum.id, @topic.id], :table_action => 'approve', :post => {@post.id => @post.id}
      @topic.reload
    end
  end

  it "should handle rejecting a post" do 
  
    @post = create_forum_post_with_end_user @topic, @myself, 'Change This Body'
    @post.save.should be_true
    @topic.reload

    assert_difference '@topic.forum_posts_count', -1 do
      post 'post_table', :path => [@forum_category.id, @forum.id, @topic.id], :table_action => 'reject', :post => {@post.id => @post.id}
      @topic.reload
    end
  end

end


