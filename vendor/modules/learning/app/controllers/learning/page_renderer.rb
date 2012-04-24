# require 'open_flash_chart_2'

class Learning::PageRenderer < ParagraphRenderer

  features '/learning/page_feature'

  paragraph :lesson_list
  paragraph :lesson
  paragraph :tracking, :ajax => true
  paragraph :module_display
  paragraph :mylessons

  def mylessons
    @mods = LearningModule.all

    @lusrs =  @mods.map { |mod| mod.module_user(myself) }.compact

    data = { :modules => @lusrs }
    render_paragraph :text => learning_page_mylessons_feature(data)
  end
  
  def lesson_list
  
    @options = paragraph_options(:lesson_list)
    
    @mod = LearningModule.find_by_id(@options.learning_module_id)
    
    unless @mod
     render_paragraph :text => 'Configure Paragraph'
     return  
    end
    
    @lusr = @mod.module_user(myself)
    
    if @lusr 
      @started = @lusr.started? 
      sections = @lusr.visible_sections if @started
    end

    
    data = { :started => @started, :user => myself, :lusr => @lusr, :sections => sections, :page_url => site_node.node_path  }
    
    render_paragraph :text => learning_page_lesson_list_feature(data)
  end
  
  def module_display
  
    @options = paragraph_options(:module_display)
    
    @mod = LearningModule.find_by_id(@options.learning_module_id)
    
    unless @mod
     render_paragraph :text => 'Configure Paragraph'
     return  
    end
    
    @lusr = @mod.module_user(myself)
    
    if !editor? && @options.force_redirect != 'no'
      if @lusr && @options.force_redirect == 'active'
        redirect_paragraph @options.active_page_url
        return
      elsif !@lusr && @options.force_redirect == 'inactive'
        redirect_paragraph @options.inactive_page_url
        return
      else
        render_paragraph :text => ''
        return
      end
    end
    
    require_js('/components/learning/javascripts/swfobject.js')
    data = { :mod => @mod, :lusr => @lusr, :user => myself, :options => @options }
    
    render_paragraph :text => learning_page_module_display_feature(data)
  end
  
  
  def lesson
  
    @options = paragraph_options(:lesson)
    
    @mod = LearningModule.find_by_id(@options.learning_module_id)
    
    unless @mod
     render_paragraph :text => 'Configure Paragraph'
     return  
    end
    
    @lusr = @mod.module_user(myself)
    
    if @lusr && @lusr.started? && params[:reset]
      @lusr.reset_user!
      redirect_paragraph :page
      return
    end
    
    
    if !@lusr
      if @options.required_registration &&  !editor?
        redirect_paragraph @options.redirect_page_url
        return
      else
        @lusr = @mod.create_module_user(myself)
      end
    end
    
    if request.post? && params[:learning] == 'start' && !@lusr.started?
      @lusr.start_module!
    end
    
    if @lusr && @lusr.started? && params[:advance]
      number = params[:advance].to_i
      while(number > 0)
        @lusr.advance_module
        number -= 1
      end
      redirect_paragraph :page
      return
    end
    
    conn_type,conn_id = page_connection
    
    if @lusr && !conn_id.blank?
      lesson = @mod.learning_lessons.find_by_id(conn_id)
      if lesson && @lusr.active_lesson?(lesson) 
        @lesson = lesson
      end
    end
    
    if @lusr
      @lesson = @lusr.last_lesson unless @lesson
    end
    
    if @lesson
      @lusr.view_lesson(@lesson)
    end
    @started = @lusr.started?
    data = { :started => @started, :user => myself, :lesson => @lesson, :page_url => site_node.node_path }
    require_js('/components/learning/javascripts/swfobject.js')
    
    render_paragraph :text => learning_page_lesson_feature(data)
  end
  
  
  def tracking
  
    @options = paragraph_options(:tracking)
    @mod = LearningModule.find_by_id(@options.learning_module_id)
    
    unless @mod 
     render_paragraph :text => 'Configure Paragraph'
     return  
    end
    
    @lusr = @mod.module_user(myself) if @mod
    if !@lusr || !@lusr.started?
     render_paragraph :text => ''
     return  
    end

    
    if params[:tracking] && params[:tracking][:field]
      dt = (Time.now + params[:tracking][:when].to_i.days).to_date
      @lusr.add_tracking_entry!(@options.goal_number,dt,params[:tracking][:field])
    end

    
    if @lusr 
    
      
    end
    
      
    
    @graph = ofc2(190,200,"website/learning/page/tracking_widget/#{@mod.id}/#{@options.goal_number}/#{@options.graph_type}")
    
    now = Time.now
    @dates =  (1..3).to_a.map do |dt| 
      [ (now - dt.days).strftime('%a'), -dt ]
    end.reverse + [['Today',0]]
    
    data = { :lusr => @lusr, :user => myself, :tracking_data => @tracking_data, :graph => @graph, :dates => @dates }
    
    output = learning_page_tracking_feature(data)
    
    if !ajax?
      output = "<div id='paragraph_#{paragraph.id}'>" + output + "</div>"
    end
    
    require_js('prototype')
    require_js('/components/learning/javascripts/swfobject.js')
    
    render_paragraph :text => output
  end

end


