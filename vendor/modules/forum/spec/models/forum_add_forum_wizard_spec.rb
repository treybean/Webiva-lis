require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../forum_test_helper'

describe ForumAddForumWizard do

  include ForumTestHelper

  reset_domain_tables :forum_categories, :content_nodes, :content_types, :site_nodes, :page_paragraphs,:page_revisions

  before(:each) do
    @category = create_forum_category
  end

  it "should add the forum category to site" do
    root_node = SiteVersion.default.root_node.add_subpage('tester')
    wizard = ForumAddForumWizard.new(
                                     :forum_category_id => @category.id,
                                     :add_to_id => root_node.id,
                                     :add_to_subpage => 'forums',
                                     :forum_page_url => 'view',
                                     :new_page_url => 'new'
                                     )
    wizard.add_to_site!

    SiteNode.find_by_node_path('/tester/forums').should_not be_nil
    SiteNode.find_by_node_path('/tester/forums/view').should_not be_nil
    SiteNode.find_by_node_path('/tester/forums/new').should_not be_nil
  end
end
