module Forum::PathHelper
  def forum_category_url_for(category_id=nil)
    category_id ||= @forum_category.id
    url_for(:controller => '/forum/manage', :action => 'category', :path => category_id)
  end

  def topics_list_url_for(forum_id=nil, category_id=nil)
    forum_id ||= @forum.id
    category_id ||= @forum_category.id
    url_for(:controller => '/forum/topics', :action => 'list', :path => [category_id, forum_id])
  end

  def posts_list_url_for(topic_id=nil, forum_id=nil, category_id=nil)
    topic_id ||= @topic.id
    forum_id ||= @forum.id
    category_id ||= @forum_category.id
    url_for(:controller => '/forum/posts', :action => 'list', :path => [category_id, forum_id, topic_id])
  end
end
