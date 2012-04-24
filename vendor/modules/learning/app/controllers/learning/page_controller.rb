

class Learning::PageController < ParagraphController

  editor_header 'Learning Paragraphs'
  
  editor_for :lesson_list, :name => "Lesson list", :inputs => [ [ :lesson_id, 'Lesson ID',:path ]] , :features => [ :learning_page_lesson_list ]
  editor_for :lesson, :name => "Lesson", :inputs => [ [ :lesson_id, 'Lesson ID',:path ]] , :features => [ :learning_page_lesson ]
  
  editor_for :tracking, :name => "Tracking Widget", :features => [:learning_page_tracking]
  editor_for :module_display, :name => 'Module Display',  :features => [ :learning_page_module_display ]
  editor_for :mylessons, :name => 'My Lessons', :feature => :learning_page_mylessons, :no_options => true
  
  user_actions :tracking_widget

  class LessonListOptions < HashModel
    attributes :learning_module_id => nil
  end
  class LessonOptions < HashModel
    attributes :learning_module_id => nil, :redirect_page_id => nil, :required_registration => false
    
    boolean_options :required_registration
    page_options :redirect_page_id
  end
  
  class TrackingOptions < HashModel
    attributes :learning_module_id => nil, :goal_number => 0, :graph_type => 'line'

    
    
  end
  
  class ModuleDisplayOptions < HashModel
    attributes :learning_module_id => nil, :active_page_id => nil, :inactive_page_id => nil, :force_redirect => 'no'
    
    page_options :active_page_id, :inactive_page_id
  end
  
  def tracking_widget
 
     title = OFC2::Title.new( '', "{font-s1ize: 12px; color: #7c8d21; text-align: center;}")
 
    @mod = LearningModule.find_by_id(params[:path][0])
    goal = params[:path][1].to_i
    graph = params[:path][2].to_s
    
    @lusr = @mod.module_user(myself) if @mod

    graph_classes = { 'line' => OFC2::LineDot, 'glass_bar' => OFC2::BarGlass }
    
    unless @lusr && graph_classes[graph]
      render :nothing => true 
      return
    end
    
    @tracking_data = @lusr.tracking.tracking_data(goal,7)
    vals =    (@tracking_data||[]).map { |elm| elm[1].to_f}

     line_1 = graph_classes[graph].new
     line_1.values= vals
     line_1.halo_size= 1  
     line_1.width= 2  
     line_1.dot_size= 4  
     line_1.colour = '#7c8d21'
   
     y = OFC2::YAxis.new  
     y.set_range(0, (vals.max||0)*1.25, 500)  
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
