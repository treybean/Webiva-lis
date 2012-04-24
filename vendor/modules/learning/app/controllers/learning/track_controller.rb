

class Learning::TrackController < ModuleController
  
  permit 'learning_manage'

  component_info 'Learning'
  
  cms_admin_paths 'content','Content' => { :controller => '/content' }
                 
  include ActiveTable::Controller
  
  active_table :learning_users_table, LearningUser, 
      [ :check, 
        hdr(:string,'end_users.full_name',:label => 'User'),
        hdr(:string,'learning_lessons.title',:label => 'Last Lesson'),
        hdr(:number,'last_section_position',:label => 'Sec#'),
        hdr(:number,'last_lesson_position',:label => 'Les#'),
        hdr(:date_range,'learning_users.last_view_at'),
        hdr(:date_range,'learning_users.created_at'),
        hdr(:boolean,'learning_users.started'),
        hdr(:boolean,'learning_users.finished')
     ]
        
  def display_learning_users_table(display=true)
    @mod = LearningModule.find(params[:path][0])
  
    active_table_action('lu') do |act,uids|
      users = LearningUser.find(:all,:conditions => {:id => uids })
      users.map(&:destroy) if act == 'delete'
    end
    @tbl = learning_users_table_generate(params,:order => 'learning_users.created_at DESC',:include => [ :end_user,:last_lesson ],:conditions => ['learning_users.learning_module_id=?',@mod.id])
    
    render :partial => 'learning_users_table' if display
  end
  
  def view
    @mod = LearningModule.find(params[:path][0])
    cms_page_path ['Content'], [ "%s Users", nil, @mod.name ]
    
    display_learning_users_table(false)
  end
  
  def sections
    active_table_action('section') do |act,sids|
      LearningSection.destroy(sids) if act == 'delete'
    end
  end
  
  active_table :user_lessons_table, LearningUserLesson,
          [ hdr(:string,'learning_sections.name'),
            hdr(:string,'learning_lessons.name'),
            hdr(:date_range,'learning_user_lessons.first_view_at'),
            hdr(:date_range,'learning_user_lessons.last_view_at'),
            hdr(:number,'views')
          ]

            
  def display_user_lessons_table(display=true)
    @lmod = LearningModule.find(params[:path][0]) unless @lmod
    @lu = @lmod.learning_users.find_by_id(params[:path][1]) unless @lu
    
    @tbl = user_lessons_table_generate(params,:order => 'first_view_at DESC',:include => [ :learning_section, :learning_lesson ], :conditions => ["learning_user_id = ?",@lu.id] )
    
    render :partial => 'user_lessons_table' if display
  end
  
  def user
    @lmod = LearningModule.find(params[:path][0])
    @lu = @lmod.learning_users.find_by_id(params[:path][1])
    @user = @lu.end_user
    cms_page_path ['Content', [ "%s Users", url_for(:action => 'view',:path => [ @lmod.id ] ), @lmod.name ] ], [ "%s",nil,@lu.end_user.name ]
    
    display_user_lessons_table(false)
    
    @graphs = []
    @lmod.goals.each_with_index do |goal,idx|
      @graphs << [goal.humanize, ofc2(800,200,"website/learning/track/widget/#{@lmod.id}/#{idx}/#{@user.id}") ] 
    end
    require_js('/components/learning/javascripts/swfobject.js')
    
  end
  
  
  def widget
 
     title = OFC2::Title.new( '', "{font-size: 12px; color: #7c8d21; text-align: center;}")
 
    @mod = LearningModule.find_by_id(params[:path][0])
    goal = params[:path][1].to_i
    
    @user = EndUser.find_by_id(params[:path][2])
    @lusr = @mod.module_user(@user) if @mod
    
    unless @lusr
      render :nothing => true 
      return
    end
    
    @tracking_data = @lusr.tracking.tracking_data(goal,40)
    vals =    (@tracking_data||[]).map { |elm| elm[1].to_i}
 
     line_1 = OFC2::LineDot.new  
     line_1.values= vals
     line_1.halo_size= 1  
     line_1.width= 2  
     line_1.dot_size= 4  
     line_1.colour = '#7c8d21'
   
     y = OFC2::YAxis.new  
     y.set_range(0, (vals.max||0)+1000, 500)  
     y.labels = ['']
     y.tick_length = 10
     y.grid_colour = '#ffffff'
     y.colour = '#ffffff'
     
     x = OFC2::XAxis.new
     x_labels = OFC2::XAxisLabels.new
     x_labels.steps = 1
     x_labels.labels = @tracking_data.map { |dt| "#{dt[0].month}/#{dt[0].day}" }.map do |lbl|
      OFC2::XAxisLabel.new(lbl,'#7c8d21',7)
     end
     x.labels = x_labels
     x.grid_colour = '#e6f5ff'
     x.colour = '#e6f5ff'
     
     
     chart = OFC2::Graph.new  
     chart.title = title
     chart.bg_colour='#FFFFFF'
     chart << line_1  
     chart.y_axis= y  
     chart.x_axis = x
   
     render :text => chart.render  

  end  

end
