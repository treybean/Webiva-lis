require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../forum_test_helper'

describe Forum::PageFeature, :type => :view do
  include ForumTestHelper

  reset_domain_tables :end_user,:forum_forums,:forum_posts,:forum_categories,:forum_topics

  it 'Initial test data validation' do
    @user = create_end_user
    @user.save
    @category = create_forum_category
    @category.save.should be_true
    @forum = create_forum_forum @category
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

  describe "Page Feature" do
    before(:each) do
      @user = create_end_user
      @user.save
      @category = create_forum_category
      @category.save
      @forum = create_forum_forum @category
      @forum.save
      @topic = create_forum_topic_with_end_user( @forum, @user )
      @topic.save
      @forum.reload
      @post = create_forum_post_with_end_user(@topic, @user)
      @post.save
      @topic.reload
      @feature = build_feature('/forum/page_feature')
      @feature.should_receive(:require_css).any_number_of_times

      @category_page_node = SiteVersion.default.root.add_subpage('category')
      @forum_page_node = SiteVersion.default.root.add_subpage('forum')
      @new_post_page_node = SiteVersion.default.root.add_subpage('new_post')
    end

    it "should display list of categories" do
      @options = Forum::PageController::CategoriesOptions.new( {:category_page_id => @category_page_node.id,
							        :forum_page_id => @forum_page_node.id,
							        :new_post_page_id => @new_post_page_node.id} )

      @pages, @categories = ForumCategory.paginate(nil, :per_page => 20, :order => 'name')
      @output = @feature.forum_page_categories_feature({:categories => @categories, :pages => @pages, :options => @options})
      @output.should include( @category.name )
    end

    it "should display list of forums" do
      @options = Forum::PageController::ListOptions.new( {:category_page_id => @category_page_node.id,
							  :forum_page_id => @forum_page_node.id} )

      @pages, @forums = @category.forum_forums.paginate(nil, :per_page => @options.forums_per_page, :order => 'weight DESC, name' )
      @output = @feature.forum_page_list_feature({:forums => @forums, :category => @category, :pages => @pages, :options => @options})
      @output.should include( @forum.name )
    end

    it "should display list of topics" do
      @options = Forum::PageController::ForumOptions.new( {:category_page_id => @category_page_node.id,
							   :forum_page_id => @forum_page_node.id,
							   :new_post_page_id => @new_post_page_node.id} )

      @pages, @topics = @forum.forum_topics.paginate(params[:forum_page], :per_page => @options.topics_per_page, :order => 'sticky, created_at DESC')
      @output = @feature.forum_page_forum_feature({:topics => @topics, :forum => @forum, :category => @category, :pages => @pages, :options => @options})
      @output.should include( @topic.subject )
    end

    it "should display list of posts" do
      @user = EndUser.new
      @options = Forum::PageController::TopicOptions.new( {:category_page_id => @category_page_node.id,
							   :forum_page_id => @forum_page_node.id,
							   :new_post_page_id => @new_post_page_node.id} )

      @pages, @posts = @topic.forum_posts.approved_posts.paginate(nil, :per_page => @options.posts_per_page, :order => 'posted_at')
      @feature.should_receive(:myself).any_number_of_times.and_return(@user)
      @output = @feature.forum_page_topic_feature({:posts => @posts, :topic => @topic, :forum => @forum, :category => @category, :pages => @pages, :options => @options})
      @output.should include( @post.subject )
    end

    it "should display a new topic form" do
      @options = Forum::PageController::NewPostOptions.new( {:category_page_id => @category_page_node.id,
							     :forum_page_id => @forum_page_node.id} )

      @user = create_end_user
      @user.save

      @feature.should_receive(:myself).and_return(@user)

      @post = @forum.forum_posts.build
      @output = @feature.forum_page_new_post_feature({:post => @post, :topic => nil, :forum => @forum, :options => @options})
      @output.should include( 'Subject' )
    end

    it "should display a new post form" do
      @options = Forum::PageController::NewPostOptions.new( {:category_page_id => @category_page_node.id,
							     :forum_page_id => @forum_page_node.id} )

      @user = create_end_user
      @user.save

      @feature.should_receive(:myself).and_return(@user)

      @post = @topic.build_post
      @output = @feature.forum_page_new_post_feature({:post => @post, :topic => @topic, :forum => @forum, :options => @options})
      @output.should include( 'Subject' )
    end

    it "should display recent topics" do
      @options = Forum::PageController::RecentOptions.new( {:category_page_id => @category_page_node.id,
							    :forum_page_id => @forum_page_node.id} )

      @pages, @topics = @forum.forum_topics.order_by_recent_topics(1.day.ago).paginate(nil, :per_page => @options.topics_per_page)
      @output = @feature.forum_page_recent_feature({:topics => @topics, :forum => @forum, :category => @category, :pages => @pages, :options => @options})
      @output.should include( @topic.subject )
    end
  end
end
