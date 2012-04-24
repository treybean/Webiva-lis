

class Forum::ManageController < ModuleController
  before_filter :find_forum_category, :find_forum

  helper 'forum/path'

  permit 'forum_manage'

  component_info 'Forum'

  # need to include 
  include ActiveTable::Controller
  active_table :forum_table,
                ForumForum,
                [ hdr(:icon, '', :width=>10),
                  hdr(:icon, :image_id, :width=>32),
                  hdr(:string, :name, :label => 'Forum Name'),
                  hdr(:string, :url),
                  hdr(:number, :forum_topics_count),
                  hdr(:boolean, :main_page),
                  hdr(:number, :weight),
                  :updated_at,
                  :created_at
                ]

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' }


  def category
    forum_path '%s Forums' / @forum_category.name
    forum_table(false)
  end

  def forum_table(display=true)
    @active_table_output = forum_table_generate params, :order => 'forum_forums.updated_at DESC', :conditions => ['forum_forums.forum_category_id = ?',@forum_category.id ]
    
    render :partial => 'forum_table' if display
  end

  def forum
    if @forum.nil?
      @forum = @forum_category.forum_forums.build
      forum_path 'Create a new Forum'.t
    else
      forum_path '%s Forum' / @forum.name, topics_list_url_for
    end

    if request.post? && params[:forum]
      if @forum.update_attributes(params[:forum])
	flash[:notice] = params[:path][1] ? 'Updated Forum Configuration'.t : 'Created a new Forum'.t
	redirect_to topics_list_url_for
      end
    end
  end

  def delete
    forum_path 'Delete Forum'.t, nil, ['%s Forum', topics_list_url_for, @forum.name]

    if request.post? && params[:destroy] == 'yes'
      @forum.destroy
      flash[:notice] = 'Deleted "%s" Forum' / @forum.name
      redirect_to forum_category_url_for
    end
  end

  private

  module ForumModule
    include Forum::AdminController::AdminModule

    def find_forum
      @forum ||= @forum_category.forum_forums.find(params[:path][1]) if params[:path][1]
    end

    def build_forum_base_path
      base = ['Content']
      if ! @forum.nil?
	base << [ '%s Forums', forum_category_url_for, @forum_category.name ]
      end
      base
    end
  end

  include ForumModule

  def forum_path(path, url=nil, append_to_base=nil)
    base = build_forum_base_path
    if ! append_to_base.nil?
      base << append_to_base
    end
    cms_page_path base, ['%s', url, path]
  end
end
