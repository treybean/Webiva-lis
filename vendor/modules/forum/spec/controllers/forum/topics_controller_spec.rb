require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../forum_test_helper'

describe Forum::TopicsController do

  include ForumTestHelper

  reset_domain_tables :end_user,:forum_forums,:forum_posts,:forum_categories,:forum_topics

  before(:each) do
    mock_editor

    @forum_category = create_forum_category
    @forum_category.save
    @forum = create_forum_forum @forum_category
    @forum.save
  end

  it "should handle table list" do 
  
    # Test all the permutations of an active table
    controller.should handle_active_table(:topic_table) do |args|
      args[:path] = [@forum_category.id, @forum.id]
      post 'topic_table', args
    end
  end

  it "should be able to create topics" do

    assert_difference 'ForumTopic.count', 1 do
      post 'topic', :path => [@forum_category.id, @forum.id], :topic => { :subject => 'Test Subject', :forum_forum_id => @forum.id, :end_user_id => @myself.id }
      @topic = ForumTopic.find(:last)
      response.should redirect_to(:controller => '/forum/posts', :action => 'list', :path => [@forum_category.id, @forum.id, @topic.id])
    end
  end

  it "should be able to edit topic" do
    @topic = create_forum_topic_with_end_user @forum, @myself, 'Change This Subject'
    @topic.save.should be_true

    assert_difference 'ForumTopic.count', 0 do
      post 'topic', :path => [@forum_category.id, @forum.id, @topic.id], :topic => { :subject => 'Test Subject' }
      response.should redirect_to(:controller => '/forum/posts', :action => 'list', :path => [@forum_category.id, @forum.id, @topic.id])
      @topic.reload
      @topic.subject.should == 'Test Subject'
    end
  end

  it "should be able to delete a topic" do
    @topic = create_forum_topic_with_end_user @forum, @myself
    @topic.save.should be_true

    assert_difference 'ForumTopic.count', -1 do
      post 'delete', :path => [@forum_category.id, @forum.id, @topic.id], :destroy => 'yes'
      response.should redirect_to(:controller => '/forum/topics', :action => 'list', :path => [@forum_category.id, @forum.id])
    end
  end

end


