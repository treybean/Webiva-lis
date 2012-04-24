class Forum::AdminController < ModuleController
  before_filter :find_forum_category, :only => ['category', 'delete']

  helper 'forum/path'

  permit 'forum_config'
  
  component_info 'Forum', :description => 'Add Forums to your website', 
                          :access => :private
                              
  content_model :forums
  
  content_action  'Create a new Forum Category', { :controller => '/forum/admin', :action => 'category' }, :permit => 'forum_config'

  register_permission_category :forum, "Forum" ,"Permissions for Writing to and Managing Forums"
  
  register_permissions :forum, [[ :manage, 'Forum Management', 'Can Manage forums and posts' ], 
                                [ :config, 'Forum Configuration', 'Can Create, Delete and Configure Forums'],
                                [ :post, 'Can Post', 'Can Post to Forums'],
                                [ :search, 'Can Search', 'Can Search Forums' ]
                             ]

  cms_admin_paths "options",
                  'Content' => { :controller => '/content' },
                  'Options' =>   { :controller => '/options' },
                  'Modules' =>  { :controller => '/modules' },
                  'Forum Options' => { :action => 'options' }

  register_action '/forum/new_post', :description => 'Forum New Post', :level => 3
  register_action '/forum/new_topic', :description => 'Forum New Topic', :level => 3

  register_handler :structure, :wizard, "Forum::WizardController"
  register_handler :webiva, :widget, "ForumWidget"

  public     

  def self.get_forums_info
    ForumCategory.find(:all, :order => 'weight, name').collect do |category| 
      {:name => "%s Forums" / category.name,
	:url => { :controller => '/forum/manage', :action=>'category', :path => category.id } ,
	:permission => { :model => category, :permission => :admin_permission, :base => :forum_manage },
	:icon => 'icons/content/forms_icon.png' }
    end
  end
  
  def options
    cms_page_path ['Options','Modules'], 'Forum Options'
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated forum module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  end

  def category
    if @forum_category.nil?
      @forum_category = ForumCategory.new(params[:forum_category] || { :add_to_site => true })
      cms_page_path ['Content'], 'Create a new Forum Category'
    else
      cms_page_path ['Content'], ['%s Forums', forum_category_url_for, @forum_category.name]
    end

    if request.post? && params[:forum_category]
      if @forum_category.update_attributes(params[:forum_category])
	flash[:notice] = params[:path][0] ? 'Updated Forum Category Configuration'.t : 'Created a new Forum Category'.t
	if @forum_category.add_to_site
	  redirect_to :controller => '/forum/wizard', :forum_category_id => @forum_category.id
	else
	  redirect_to forum_category_url_for
	end
      end
    end
  end

  def delete
    cms_page_path ['Content', ['%s Forums', forum_category_url_for, @forum_category.name]], 'Delete Forum Category'

    if request.post? && params[:destroy] == 'yes'
      @forum_category.destroy
      flash[:notice] = 'Deleted "%s" Forum Category' / @forum_category.name
      redirect_to :controller => '/content', :action => 'index'
    end
  end

  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  class Options < HashModel
    attributes :subscription_template_id => nil

    integer_options :subscription_template_id
  end
  
  module AdminModule
    include Forum::PathHelper

    def find_forum_category
      @forum_category ||= ForumCategory.find(params[:path][0]) if params[:path][0]
    end
  end

  include AdminModule
end
