

class Learning::AdminController < ModuleController
  permit 'learning_config'

  component_info 'Learning', :description => 'Learning support', 
                              :access => :private
                    
  register_handler :members, :view,  "Learning::UserController"
                              
  # Register a handler feature
  register_permission_category :learning, "Learning" ,"Permissions related to Learning"
  
  register_permissions :learning, [ [ :manage, 'Manage Learning', 'Manage Learning' ],
                                  [ :config, 'Configure Learning', 'Configure Learning' ]
                                  ]

  register_handler :shop, :product_feature, "Learning::ShopFeature"
  cms_admin_paths "options",
                   "Options" =>   { :controller => '/options' },
                   "Modules" =>  { :controller => '/modules' },
                   "Learning Options" => { :action => 'index' }
 
  content_model :modules
  
  register_cron :activate_lessons, "Learning::Cron"
  
  linked_models :end_user, 
                [ :learning_user ]
  

  content_action  'Create a learning module', { :controller => '/learning/manage', :action => 'create' }, :permit => 'learning_config' 
  
  def self.get_modules_info
    LearningModule.find(:all,:order =>'name').collect do |mod|
      [ { :name => mod.name, :url => {:controller => '/learning/manage',:action => 'view', :path => mod.id },:permission => 'learning_manage' },
        { :name => mod.name + " Users", :url => {:controller => '/learning/track',:action => 'view', :path => mod.id },:permission => 'learning_manage' },
      ]
    end.flatten
  end

 
 def options
    cms_page_path ['Options','Modules'],"Learning Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && params[:options] && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Learning module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
  
  
  end
  
end
