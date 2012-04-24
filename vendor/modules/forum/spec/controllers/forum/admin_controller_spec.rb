require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../forum_test_helper'

describe Forum::AdminController do

  include ForumTestHelper

  reset_domain_tables :end_user,:forum_forums,:forum_posts,:forum_categories,:forum_topics

  it "should be able to create categories" do
    mock_editor

    assert_difference 'ForumCategory.count', 1 do
      post 'category', :path => [], :forum_category => { :name => 'Test Category', :content_filter => 'markdown_safe' }
      @forum_category = ForumCategory.find(:last)
      response.should redirect_to(:controller => '/forum/manage', :action => 'category', :path => @forum_category.id)
    end
  end

  it "should be able to edit a category" do
    mock_editor

    @forum_category = create_forum_category 'Change This Forum Category Name'
    @forum_category.save.should be_true

    assert_difference 'ForumCategory.count', 0 do
      post 'category', :path => [@forum_category.id], :forum_category => { :name => 'Test Category' }
      @forum_category.reload
      response.should redirect_to(:controller => '/forum/manage', :action => 'category', :path => @forum_category.id)
      @forum_category.name.should == 'Test Category'
    end
  end

  it "should be able to delete a category" do
    mock_editor

    @forum_category = create_forum_category 'Delete This Forum Category'
    @forum_category.save.should be_true

    assert_difference 'ForumCategory.count', -1 do
      post 'delete', :path => [@forum_category.id], :destroy => 'yes'
      response.should redirect_to(:controller => '/content', :action => 'index')
    end
  end

end


