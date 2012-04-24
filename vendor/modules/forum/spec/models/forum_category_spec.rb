require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../forum_test_helper'

describe ForumCategory do

  include ForumTestHelper

  reset_domain_tables :forum_forums,:forum_posts,:forum_categories,:forum_topics

  it "should require a name and content_filter" do
    @cat = ForumCategory.new()

    @cat.valid?

    @cat.should have(1).errors_on(:name)
    @cat.should have(1).errors_on(:content_filter)
  end

  it "should be able to create a new forum and generate a url" do
    @cat = ForumCategory.new :name => 'Test Category', :content_filter => 'markdown_safe'
    @cat.save.should be_true

    @cat.url.should == 'test-category'
  end

  it 'should only allow valid filters' do
    ForumCategory.filter_user_options.each do |ele|
      @cat = ForumCategory.new :name => 'Test Category', :content_filter => ele[1]
      @cat.save.should be_true
    end
  end
end
