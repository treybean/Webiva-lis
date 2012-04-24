require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../forum_test_helper'

describe Forum::ManageController do

  include ForumTestHelper

  reset_domain_tables :end_user,:forum_forums,:forum_posts,:forum_categories,:forum_topics

  before(:each) do

    @forum_category = create_forum_category
    @forum_category.save
  end

  it "should handle table list" do 
    mock_editor
    # Test all the permutations of an active table

    controller.should handle_active_table(:forum_table) do |args|
      args[:path] = [@forum_category.id]
      post 'forum_table', args
    end
  end

  it "should be able to create forums" do
    mock_editor

    assert_difference 'ForumForum.count', 1 do
      post 'forum', :path => [@forum_category.id], :forum => { :name => 'Test Forum' }
      @forum = ForumForum.find(:last)
      response.should redirect_to(:controller => '/forum/topics', :action => 'list', :path => [@forum_category.id, @forum.id])
    end
  end

  it "should be able to edit forum" do
    mock_editor

    @forum = create_forum_forum @forum_category, 'Change This Forum Name'
    @forum.save.should be_true

    assert_difference 'ForumForum.count', 0 do
      post 'forum', :path => [@forum_category.id, @forum.id], :forum => { :name => 'Test Forum' }
      response.should redirect_to(:controller => '/forum/topics', :action => 'list', :path => [@forum_category.id, @forum.id])
      @forum.reload
      @forum.name.should == 'Test Forum'
    end
  end

  it "should be able to delete a forum" do
    mock_editor

    @forum = create_forum_forum @forum_category
    @forum.save.should be_true

    assert_difference 'ForumForum.count', -1 do
      post 'delete', :path => [@forum_category.id, @forum.id], :destroy => 'yes'
      response.should redirect_to(:controller => '/forum/manage', :action => 'category', :path => @forum_category.id)
    end
  end

end


