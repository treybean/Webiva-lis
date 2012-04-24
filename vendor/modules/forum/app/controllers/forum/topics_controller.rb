

class Forum::TopicsController < ModuleController
  before_filter :find_forum_category, :find_forum, :find_topic

  helper 'forum/path'

  permit 'forum_manage'

  component_info 'Forum'

  # need to include 
  include ActiveTable::Controller
  active_table :topic_table,
                ForumTopic,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, 'forum_topics.subject', :label => 'Topics'),
                  hdr(:string, 'forum_topics.posted_by'),
                  :permalink,
                  hdr(:number, 'forum_topics.forum_posts_count'),
                  hdr(:number, 'forum_topics.activity_count'),
                  hdr(:number, 'forum_topics.sticky'),
                  :updated_at,
                  :created_at
                ]

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' }

  def list
    topics_path '%s Forum' / @forum.name
    topic_table(false)
  end

  def topic_table(display=true)

    active_table_action('topic') do |act,tids|
      ForumTopic.find(tids,:conditions => { :forum_forum_id => @forum.id }).map(&:destroy) if act == 'delete'
    end

    @active_table_output = topic_table_generate params, :order => 'forum_topics.updated_at DESC', :conditions => ['forum_topics.forum_forum_id = ?',@forum.id ]

    render :partial => 'topic_table' if display
  end

  def topic
    if @topic.nil?
      @topic = @forum.forum_topics.build :end_user => myself
      topics_path 'Create a new Topic'.t
    else
      topics_path @topic.subject, posts_list_url_for
    end

    if request.post? && params[:topic]
      if @topic.update_attributes(params[:topic])
	flash[:notice] = params[:path][2] ? 'Updated Topic'.t : 'Created a new Topic'.t
	redirect_to posts_list_url_for
      end
    end
  end

  def delete
    topics_path 'Delete Topic'.t, nil, ['%s', posts_list_url_for, @topic.subject]

    if request.post? && params[:destroy] == 'yes'
      @topic.destroy
      flash[:notice] = 'Deleted Topic'.t
      redirect_to topics_list_url_for
    end
  end

  private
  module TopicsModule
    include  Forum::ManageController::ForumModule

    def find_topic
      @topic ||= @forum.forum_topics.find(params[:path][2]) if params[:path][2]
    end

    def build_topics_base_path
      base = build_forum_base_path
      if ! @topic.nil?
	base << [ '%s Forum', topics_list_url_for, @forum.name ]
      end
      base
    end
  end

  include TopicsModule

  def topics_path(path, url=nil, append_to_base=nil)
    base = build_topics_base_path
    if ! append_to_base.nil?
      base << append_to_base
    end
    cms_page_path base, ['%s', url, path]
  end
end
