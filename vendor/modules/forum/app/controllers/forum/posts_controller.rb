

class Forum::PostsController < ModuleController
  before_filter :find_forum_category, :find_forum, :find_topic, :find_post

  helper 'forum/path'

  permit 'forum_manage'

  component_info 'Forum'

  # need to include 
  include ActiveTable::Controller
  active_table :post_table,
                ForumPost,
                [ hdr(:icon, '', :width=>10),
                  hdr(:icon, '', :width=>28),
                  hdr(:options, 'forum_posts.approved', :options => [['Approved',1],['Rejected',0]], :icon => 'icons/table_actions/rating_none.gif', :width => '32'),
                  hdr(:string, 'forum_posts.posted_by'),
                  hdr(:date_range, 'forum_posts.posted_at', :label => 'Post')
                ]

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' }

  def list
    posts_path @topic.subject
    post_table(false)
  end

  def post_table(display=true)
    if(request.post? && params[:table_action] && params[:post].is_a?(Hash)) 
      
      case params[:table_action]
      when 'delete':
	  params[:post].each do |entry_id,val|
          ForumPost.destroy(entry_id.to_i)
	end

      when 'approve':
	  params[:post].each do |entry_id,val|
	  post = ForumPost.find(entry_id.to_i)
	  post.approved = true
	  post.save
	end

      when 'reject':
	  params[:post].each do |entry_id,val|
	  post = ForumPost.find(entry_id.to_i)
	  post.approved = false
	  post.save
	end

      end
    end
    
    @active_table_output = post_table_generate params, :order => 'forum_posts.posted_at DESC', :conditions => ['forum_posts.forum_topic_id = ?',@topic.id ]

    render :partial => 'post_table' if display
  end

  def post
    if @post.nil?
      @post = @topic.build_post(:subject => @topic.default_subject, :end_user => myself)
      posts_path 'Create a new Post'.t
    else
      posts_path 'Update Post'.t
    end

    if request.post? && params[:post]
      if @post.update_attributes(params[:post])
	flash[:notice] = params[:path][3] ? 'Updated Post'.t : 'Created a new Post'.t
	redirect_to posts_list_url_for
      end
    end
  end

  private
  module PostsModule
    include  Forum::TopicsController::TopicsModule

    def find_post
      @post ||= @topic.forum_posts.find(params[:path][3]) if params[:path][3]
    end

    def build_posts_base_path
      base = build_topics_base_path
      if ! @post.nil?
	base << [ '%s', posts_list_url_for, @topic.subject ]
      end
      base
    end
  end

  include PostsModule

  def posts_path(path, url=nil)
    base = build_posts_base_path
    cms_page_path base, ['%s', url, path]
  end
end
