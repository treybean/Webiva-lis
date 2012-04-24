# Copyright (C) 2010 Cykod LLC.

class Forum::WizardController < ModuleController
  
  permit 'forum_config'

  component_info 'Forum'
  
  cms_admin_paths 'website'

  def self.structure_wizard_handler_info
    { :name => "Add a Forum to your Site",
      :description => 'This wizard will add an existing forum to a url on your site.',
      :permit => "forum_config",
      :url => { :controller => '/forum/wizard' }
    }
  end

  def index
    cms_page_path ["Website"],"Add a Forum to your site structure"

    @forum_wizard = ForumAddForumWizard.new(params[:wizard] || {  :forum_category_id => params[:forum_category_id].to_i})
    if request.post? 
      if !params[:commit] 
        redirect_to :controller => '/structure', :action => 'wizards'
      elsif  @forum_wizard.valid?
        @forum_wizard.add_to_site!
        flash[:notice] = "Added forum to site"
        redirect_to :controller => '/structure'
      end
    end
  end
  

end
