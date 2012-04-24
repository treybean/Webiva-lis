

class Learning::ManageController < ModuleController
  
  permit 'learning_configure', :only => 'learning_configure'
  permit 'learning_manage', :except =>  'learning_configure'

  component_info 'Learning'
  
  cms_admin_paths 'content','Content' => { :controller => '/content' }
                 

  def create
    cms_page_path [ "Content"],"Create a Learning Module"
    
    @learning_module = LearningModule.find_by_id(params[:path][0]) || LearningModule.new
    
    if request.post? && params[:learning_module] 
      if @learning_module.update_attributes(params[:learning_module])
        redirect_to :action => 'view', :path => [ @learning_module.id ]
      end
    end
  end
  
  def reorder_sections
    @mod = LearningModule.find(params[:path][0])
    if params['sections'].is_a?(Array)
      params['sections'].each_with_index do |section_id,idx|
        LearningSection.update(section_id,:position => idx + 1)
      end
    end
    render :nothing => true
  end
  
  def reorder
    @mod = LearningModule.find(params[:path][0])
    @section = @mod.learning_sections.find(params[:path][1])
    if params['section_lesson_' + @section.id.to_s].is_a?(Array)
      params['section_lesson_' + @section.id.to_s].each_with_index do |lesson_id,idx|
        LearningLesson.update(lesson_id,:position => idx + 1, :learning_section_id => @section.id)
      end
    end
    render :nothing => true
  end
  
  def remove_lesson
    @mod = LearningModule.find(params[:path][0])
    @mod.learning_lessons.find(params[:lesson_id]).destroy
    render :nothing => true
  end
  
  def remove_section
    @mod = LearningModule.find(params[:path][0])
    @mod.learning_sections.find(params[:section_id]).destroy
    render :nothing => true
  end

  
  def view
    @mod = LearningModule.find(params[:path][0])
    cms_page_path [ "Content"], @mod.name
    
    @sections = @mod.learning_sections
  end
  
  def edit
    @mod = LearningModule.find(params[:path][0])
    @section = @mod.learning_sections.find(params[:path][1])
    @lesson = @section.learning_lessons.find_by_id(params[:path][2]) || @section.learning_lessons.build(:learning_module_id => @mod.id)
    @content = @lesson.content_html
    cms_page_path [ "Content", [ "%s", nil, @mod.name ] ], @lesson.id ? 'Edit Lesson' : 'Create Lesson'
    
    if request.post? && params[:lesson]
      if @lesson.update_attributes(params[:lesson])
        redirect_to :action => 'view' ,:path => @mod.id 
      end
      
    end
  
  end
  
  def update
    @mod = LearningModule.find(params[:path][0])
    @lesson = LearningLesson.new(params[:lesson])
    @content = @lesson.generate_content_html
    render :partial => 'update'
  end
  
  def section
    @mod = LearningModule.find(params[:path][0])
    cms_page_path [ "Content", [ "%s", nil, @mod.name ] ], 'Section'
    @section = @mod.learning_sections.find_by_id(params[:path][1]) || @mod.learning_sections.build
    
    if request.post? && params[:section]
      if @section.update_attributes(params[:section])
        redirect_to  :action => 'view' ,:path => @mod.id 
      end
    end
  end  
  
  
  include ActiveTable::Controller
  
  active_table :sections_table, LearningSection, [ :check, :name ]
  
  def sections
    active_table_action('section') do |act,sids|
      LearningSection.destroy(sids) if act == 'delete'
    end
  end
  

end
