

module ForumTestHelper
  def create_end_user(email='test@webiva.com', options={:first_name => 'Test', :last_name => 'User'})
    EndUser.push_target(email, options)
  end

  def create_client_user(email='test@webiva.com', options={})
    user = EndUser.push_target(email, options)
    user.user_class = UserClass.client_user_class
    user.client_user_id = 1
    user
  end

  def create_forum_category(name='Test Category', content_filter='markdown_safe', options={})
    ForumCategory.new({:name => 'Test Category', :content_filter => content_filter}.merge(options))
  end

  def create_forum_forum(category=nil, name='Test Forum', options={})
    if category.nil?
      ForumForum.new( {:name => name}.merge(options) )
    else
      category.forum_forums.build( {:name => name}.merge(options) )
    end
  end

  def create_forum_topic(forum=nil, subject='Test Topic Subject', options={})
    if forum.nil?
      ForumTopic.new( {:subject => subject}.merge(options) )
    else
      forum.forum_topics.build( {:subject => subject}.merge(options) )
    end
  end

  def create_forum_topic_with_end_user(forum=nil, end_user=nil, subject='Test Topic Subject', options={})
    create_forum_topic( forum, subject, {:end_user => end_user}.merge(options) )
  end

  def create_forum_post(topic=nil, body='test post', options={})
    if topic.nil?
      ForumPost.new( {:body => body}.merge(options) )
    else
      topic.build_post( {:body => body}.merge(options) )
    end
  end

  def create_forum_post_with_end_user(topic=nil, end_user=nil, body='test post', options={})
    create_forum_post(topic, body, {:end_user => end_user}.merge(options))
  end
end
