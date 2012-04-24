
class Calendar::OptionsController < ModuleController
  
  permit 'calendar_admin'

  component_info 'Calendar'

 cms_admin_paths "content",
                   "Content" =>   { :controller => '/content' },
                   "Appointments" =>  { :controller => '/calendar/manage' },
                   "Configure" => { :controller => '/calendar/slots', :action => 'index' }

  def index
     cms_page_path [ "Content", "Appointments","Configure"],'Calendar Options'
     
     
      @options = Calendar::Utility.options(params[:options])
      
      if request.post? && params[:options] && @options.valid?
        Configuration.set_config_model(@options)
        flash[:notice] = 'Updated Calendar Options'
        cms_page_redirect "Configure"
      end
  
  end
  
  



end
