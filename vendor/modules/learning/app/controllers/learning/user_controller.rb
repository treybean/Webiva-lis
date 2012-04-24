

class Learning::UserController < ModuleController


    component_info "Learning" 
    
    def self.members_view_handler_info
    { 
      :name => "Online Learning",
      :controller => '/learning/user',
      :action => 'view'
    }
   end  
   
   def view
    @tab = params[:tab]
    @user = EndUser.find(params[:path][0])
    
    
    @mod_opts = Learning::AdminController.module_options()
    
    if request.post? && params[:act]
      @mod = LearningModule.find(params[:module_id])
      @lusr = @mod.module_user(@user)
      case params[:act]
      when 'activate'
        @lusr = @mod.create_module_user(@user)
      when 'deactivate'
        @lusr.destroy
      when 'reset'
        @lusr.reset_user!
      when 'advance':
        @lusr.advance_module
      end      
    end
    
    @learning_modules = LearningModule.find(:all)
    @learning_users = LearningUser.find(:all,:conditions => [ 'end_user_id = ?',@user.id ]).index_by(&:learning_module_id)
    
    render :partial => 'view'
    
   end
  
  

end
