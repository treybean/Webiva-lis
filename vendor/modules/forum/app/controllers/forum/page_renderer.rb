# Copyright (C) 2009 Pascal Rettig.


class Forum::PageRenderer < ParagraphRenderer

  include EndUserTable::Controller

  features '/forum/page_feature'

  paragraph :categories
  paragraph :list
  paragraph :forum
  paragraph :topic
  paragraph :new_post
  paragraph :edit_post
  paragraph :recent

  def categories
    @options = paragraph_options(:categories)

    conn_type, conn_id = page_connection
    @category = ForumCategory.find_by_url conn_id if conn_type == :url && ! conn_id.blank?
    return render_paragraph :text => '' if @category

    result = renderer_cache(ForumCategory) do |cache|
      @categories = ForumCategory.find(:all, :order => 'weight, name' )
      cache[:output] = forum_page_categories_feature
    end

    render_paragraph :text => result.output
  end

  def list
    @options = paragraph_options(:list)

    if editor?
      @category = ForumCategory.find(:first)
    elsif @options.forum_category_id.blank?
      conn_type, conn_id = page_connection
      @category = ForumCategory.find_by_url conn_id if conn_type == :url && ! conn_id.blank?
    else
      @category = ForumCategory.find @options.forum_category_id
    end

    return render_paragraph :text => '' unless @category

    forum_page = (params[:forum_page] || 1).to_i

    result = renderer_cache(@category, forum_page) do |cache|
      @pages, @forums = @category.forum_forums.paginate(forum_page, :per_page => @options.forums_per_page, :order => 'weight, name' )
      cache[:output] = forum_page_list_feature
    end

    if ! result.output
      return render_paragraph :text => ''
    end

    set_page_connection :category, @category
    set_title @category.name, 'category'
    render_paragraph :text => result.output
  end

  def forum
    @options = paragraph_options(:forum)

    if editor?
      if @options.forum_forum_id.blank?
	@forum = ForumForum.find(:first)
      else
	@forum = ForumForum.find_by_id @options.forum_forum_id
      end

      return render_paragraph :text => 'No forum found.' if @forum.nil?

    elsif ! @options.forum_forum_id.blank?
      @forum = ForumForum.find @options.forum_forum_id
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @forum
    else
      conn_type, conn_id = page_connection(:forum)
      @forum = ForumForum.find_by_url conn_id if conn_type == :url && ! conn_id.blank?
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @forum
    end

    forum_page = (params[:forum_page] || 1).to_i
    conn_type, conn_id = page_connection(:topic)
    must_fetch_topic = (conn_type == :id && ! conn_id.blank? && ! editor?)

    return render_paragraph :text => '' if must_fetch_topic

    cache_obj = must_fetch_topic ? [ForumTopic, conn_id.to_i] : @forum

    result = renderer_cache(cache_obj, forum_page) do |cache|
      @topic = @forum.forum_topics.find_by_permalink conn_id if conn_id && must_fetch_topic
      @topic ||= @forum.forum_topics.find_by_id conn_id.to_i if must_fetch_topic

      if @forum && ! must_fetch_topic
	@pages, @topics = @forum.forum_topics.paginate(forum_page, :per_page => @options.topics_per_page, :order => 'sticky DESC, created_at DESC')
      end

      cache[:output] = forum_page_forum_feature
    end

    set_page_connection :forum, @forum
    set_title @forum.name, 'forum'
    render_paragraph :text => result.output
  end

  def topic
    @options = paragraph_options(:topic)

    if editor?
      if @options.forum_forum_id.blank?
        @topic = ForumTopic.find(:first)
        @forum = @topic.forum_forum if @topic
      else
        @forum = ForumForum.find_by_id @options.forum_forum_id
        @topic = @forum.forum_topics.find(:first) if @forum;
      end

      return render_paragraph :text => 'No forum found.' if @forum.nil?
    else
      if @options.forum_forum_id.blank?
        conn_type, conn_id = page_connection(:forum)
        @forum = ForumForum.find_by_url conn_id if conn_type == :url && ! conn_id.blank?
      else
        @forum = ForumForum.find @options.forum_forum_id
      end

      conn_type, conn_id = page_connection(:topic)
      if conn_type == :id && ! conn_id.blank? && @forum
        @topic = @forum.forum_topics.find_by_permalink conn_id
        @topic ||= @forum.forum_topics.find_by_id conn_id
      end
    end

    if @topic
      increment_topic_views @topic

      posts_page = (params[:posts_page] || 1).to_i
      display_string = "#{posts_page}"

      default_subscription_template_id = Forum::AdminController.module_options.subscription_template_id
      if @topic.subscribe?(myself, default_subscription_template_id)
        @subscription = ForumSubscription.find_by_end_user_id_and_forum_topic_id(myself.id, @topic.id)
        @subscription = @topic.build_subscription(myself) if @subscription.nil?
        display_string << "_#{@subscription.id ? 'unsubscribed' : 'subscribed'}"
        if request.post?
          if params[:subscribe] && params[:subscribe].blank?
            @subscription.destroy if @subscription.subscribed?
            @subscription = @topic.build_subscription(myself)
            flash[:notice] = 'Unsubscribed from topic';
          else
            @subscription.save unless @subscription.subscribed?
            flash[:notice] = 'Subscribed to topic';
          end
        end
      end

      display_string << "_edit_#{myself.id}" if @options.edit_post_page_url

      result = renderer_cache(@topic, display_string, :skip => request.post?) do |cache|
        @pages, @posts = @topic.forum_posts.approved_posts.paginate(posts_page, :per_page => @options.posts_per_page, :order => 'posted_at')
        cache[:output] = forum_page_topic_feature
      end

      set_content_node(@topic)
      set_page_connection :topic, @topic
      set_title @forum.name, 'forum'
      set_title @topic.subject[0..68], 'subject'
      render_paragraph :text => result.output
    else
      render_paragraph :text => ''
    end
  end

  def new_post
    @options = paragraph_options(:new_post)

    if editor?
      if @options.forum_forum_id.blank?
	@forum = ForumForum.find(:first)
      else
	@forum = ForumForum.find_by_id @options.forum_forum_id
      end

      return render_paragraph :text => 'No forum found.' if @forum.nil?
    else
      if @options.forum_forum_id.blank?
	conn_type, conn_id = page_connection
	if conn_type == :forum
	  @forum = conn_id
	elsif conn_type == :topic
	  @topic = conn_id
	  @forum = @topic.forum_forum
	elsif conn_type == :forum_path
	  @forum = ForumForum.find_by_url conn_id
	  raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @forum

	  conn_type, conn_id = page_connection(:topic)
          if conn_type == :id && ! conn_id.blank?
            @topic = @forum.forum_topics.find_by_permalink conn_id
            @topic ||= @forum.forum_topics.find_by_id conn_id
          end

          if @topic
            conn_type, conn_id = page_connection(:post)
            @reply_to_post = @topic.forum_posts.find_by_id conn_id if conn_type == :id && ! conn_id.blank?
            @reply_to_post = @topic.first_post unless @reply_to_post
          end
	else
	  return render_paragraph :text => '[Configure page connections]'
	end
      else
	@forum = ForumForum.find @options.forum_forum_id

	conn_type, conn_id = page_connection(:content)
	if conn_type == :content
	  @content = conn_id
	end
      end
    end

    cache_obj = @topic ? @topic : @forum

    allowed_to_post = true
    if @topic
      if ! @forum.allowed_to_create_post?(myself)
	allowed_to_post = false
      end
    elsif ! @forum.allowed_to_create_topic?(myself)
      allowed_to_post = false
    end

    display_string = allowed_to_post ? 'allowed' : 'not_allowed'
    display_string << (myself.missing_name? ? '_missing_name' : '_have_name')
    display_string << "_#{@reply_to_post.id}" if @reply_to_post

    result = renderer_cache(cache_obj, display_string, :skip => request.post?) do |cache|

      if allowed_to_post
	@post = @topic ? @topic.build_post : @forum.forum_posts.build
	@post.end_user = myself
        @post.subscribe = true

	if @content
	  @post.content_type = @content[0]
	  @post.content_id = @content[1]
	end

	if request.post? && params[:post]
	  if @post.can_add_attachments?
	    handle_file_upload params[:post], 'attachment_id', {:folder => @post.upload_folder_id}
	  end

          @post.subscribe = params[:post][:subscribe].blank? ? false : true

	  if @post.update_attributes(params[:post].slice(:subject, :body, :attachment_id, :posted_by, :tag_names))

	    action = @topic ? 'new_post' : 'new_topic'
	    action_path = "/forum/#{action}"
	    atr = @topic ? @post : @post.forum_topic
	    paragraph_action(myself.action(action_path, :target => @post, :identifier => @post.subject))
	    paragraph.run_triggered_actions(atr,action,myself)

	    posts_page = ((@post.forum_topic.forum_posts.size-1) / @options.posts_per_page).to_i + 1
	    if posts_page > 1
	      posts_url = @options.forum_page_url + '/' + @forum.url + '/' + @post.forum_topic.url + '?posts_page=' + posts_page.to_s
	    else
	      posts_url = @options.forum_page_url + '/' + @forum.url + '/' + @post.forum_topic.url
	    end

	    default_subscription_template_id = Forum::AdminController.module_options.subscription_template_id
	    @post.send_subscriptions!( {:url => posts_url}, default_subscription_template_id )

            if @post.forum_topic.subscribe?(myself, default_subscription_template_id)
              @subscription = ForumSubscription.find_by_end_user_id_and_forum_topic_id(myself.id, @post.forum_topic.id)
              @subscription = @post.forum_topic.build_subscription(myself) if @subscription.nil?

              if @post.subscribe
                @subscription.save unless @subscription.subscribed?
              else
                @subscription.destroy if @subscription.subscribed?
              end
            end

	    return redirect_paragraph posts_url
	  end
	end
      end

      cache[:output] = forum_page_new_post_feature
    end

    set_title @topic.subject[0..68], 'subject' if @topic
    set_title @forum.name, 'forum'
    set_title @topic ? @topic.subject[0..68] : @forum.name
    render_paragraph :text => result.output
  end

  def edit_post
    @options = paragraph_options(:edit_post)

    if editor?
      @post = ForumPost.find :first
      @topic = @post.forum_topic
      @forum = @post.forum_forum
      return render_paragraph :text => 'No post found.' if @post.nil?
    else
      conn_type, conn_id = page_connection(:forum)
      @forum = ForumForum.find_by_url conn_id
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @forum

      conn_type, conn_id = page_connection(:topic)
      unless conn_id.blank?
        @topic = @forum.forum_topics.find_by_permalink conn_id
        @topic ||= @forum.forum_topics.find_by_id conn_id
      end
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @topic

      conn_type, conn_id = page_connection(:post)
      @post = @topic.forum_posts.find_by_id conn_id
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @post
    end

    if ! editor?
      posts_url = @options.forum_page_url + '/' + @forum.url + '/' + @post.forum_topic.url
      return redirect_paragraph posts_url if @post.end_user_id.nil? ||  myself.id != @post.end_user_id

      if request.post? && params[:post]
        if @post.can_add_attachments?
          handle_file_upload params[:post], 'attachment_id', {:folder => @post.upload_folder_id}
        end

        if @post.update_attributes(params[:post].slice(:subject, :body, :attachment_id, :posted_by))
          return redirect_paragraph posts_url
        end
      end
    end

    set_title @topic.subject[0..68], 'subject' if @topic
    set_title @forum.name, 'forum'
    set_title @topic ? @topic.subject[0..68] : @forum.name
    render_paragraph :feature => :forum_page_edit_post
  end

  def recent
    return render_paragraph :text => '[Configure Page Connections]' unless recent_options

    forum_page = (params[:forum_page] || 1).to_i
    display_string = "#{forum_page}"
    if @content
      display_string << "_#{@content[0]}_#{@content[1]}"
    end

    cache_obj = nil
    if @forum_url
      cache_obj = [ForumForum, @forum_url]
    elsif @category_path
      cache_obj = [ForumCategory, @category_path]
    else
      cache_obj = ForumTopic
      display_string << '_recent'
    end

    result = renderer_cache(cache_obj, display_string) do |cache|
      if @forum_url
        @forum = ForumForum.find_by_url @forum_url unless @forum
        raise MissingPageException.new( site_node, language ) unless @forum

        @category = @forum.forum_category unless @category
        raise MissingPageException.new( site_node, language ) unless @category.url == @category_path

        if @content
          @pages, @topics = @forum.forum_topics.topics_for_content(*@content).order_by_recent_topics(1.day.ago).paginate(forum_page, :per_page => @options.topics_per_page)
        else
          @pages, @topics = @forum.forum_topics.order_by_recent_topics(1.day.ago).paginate(forum_page, :per_page => @options.topics_per_page)
        end
      elsif @category_path
        @category = ForumCategory.find_by_url @category_path unless @category
        raise MissingPageException.new( site_node, language ) unless @category

        @pages, @topics = @category.forum_topics.order_by_recent_topics(1.day.ago).paginate(forum_page, :per_page => @options.topics_per_page)
      else
        @pages, @topics = ForumTopic.order_by_recent_topics(1.day.ago).paginate(forum_page, :per_page => @options.topics_per_page)
      end

      cache[:output] = forum_page_recent_feature
    end

    render_paragraph :text => result.output
  end

  protected

  def recent_options
    @options = paragraph_options(:recent)

    if editor?
      if ! @options.forum_forum_id.blank?
	@forum = ForumForum.find_by_id @options.forum_forum_id
	@category = @forum.forum_category if @forum
      elsif ! @options.forum_category_id.blank?
	return true if @options.forum_category_id == -1
	@category = ForumCategory.find_by_id @options.forum_category_id
      else
	@category = ForumCategory.find(:first)
      end

      return false if @category.nil?
    elsif ! @options.forum_forum_id.blank?
      @forum = ForumForum.find @options.forum_forum_id
      @category = @forum.forum_category
    elsif ! @options.forum_category_id.blank?
      return true if @options.forum_category_id == -1
      @category = ForumCategory.find @options.forum_category_id
      conn_type, conn_id = page_connection(:forum)
      @forum_url = conn_id if ! conn_id.blank? && conn_type == :url
    else
      conn_type, conn_id = page_connection
      if conn_type == :category
	@category = conn_id
      elsif conn_type == :forum
	@forum = conn_id
	@category = @forum.forum_category
      elsif conn_type == :category_path
	@category_path = conn_id if ! conn_id.blank?

	conn_type, conn_id = page_connection(:forum)
	@forum_url = conn_id if ! conn_id.blank? && conn_type == :url
      else
	return false
      end
    end

    conn_type, conn_id = page_connection(:content)
    @content = conn_id if conn_type == :content && ! conn_id.blank?

    @category_path = @category.url if @category
    @forum_url = @forum.url if @forum

    true
  end

  def increment_topic_views(topic)
    session[:forum_topics] ||= {}
    return if session[:forum_topics].has_key?(topic.id)
    topic.increment_views
    session[:forum_topics][topic.id] = true
  end
end
