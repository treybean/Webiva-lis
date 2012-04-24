
class Rewards::AdminController < ModuleController

  component_info 'Rewards', :description => 'Rewards support', :access => :public, :dependencies => ['shop']
                              
  # Register a handler feature
  register_permission_category :rewards, "Rewards", "Permissions related to Rewards"
  
  register_permissions :rewards, [[:manage, 'Manage Rewards', 'Manage Rewards'],
                                  [:config, 'Configure Rewards', 'Configure Rewards']

                                 ]

  content_model :rewards

  cms_admin_paths "options",
    "Rewards Options" => {:action => 'index'},
    "Options" => {:controller => '/options'},
    "Modules" => {:controller => '/modules'}

  permit 'rewards_config'

  register_handler :shop, :product_feature, "Rewards::AddRewardsShopFeature"
  register_handler :members, :view,  "Rewards::ManageUserController"
  register_handler :trigger, :actions, 'Rewards::Trigger'
  register_handler :user_segment, :fields, 'RewardsUserSegmentField'
  register_handler :user_segment, :fields, 'RewardsTransactionSegmentField'

  public
 
  def self.get_rewards_info
    [{:name => 'Rewards', :url => {:controller => '/rewards/manage', :action => 'users'}}]
  end

  def options
    cms_page_path ['Options','Modules'], "Rewards Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Rewards module options".t 
      redirect_to :controller => '/modules'
    end    
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
    attributes :rewards_value => nil

    integer_options :rewards_value

    validates_presence_of :rewards_value

    options_form(
                 fld(:rewards_value, :text_field, :description => 'the number rewards equal to a USD dollar', :unit => 'rewards')
                 )

    def validate
      self.errors.add(:rewards_value, 'is invalid') if self.rewards_value && self.rewards_value <= 0
    end
  end
end
