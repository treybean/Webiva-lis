
class Learning::PageFeature < ParagraphFeature

  feature :learning_page_mylessons, :default_feature => <<-FEATURE
  <cms:lessons>
    <ul>
    <cms:lesson>
      <li><cms:link><cms:name/></cms:link></li>
    </cms:lesson>
    </ul>
  </cms:lessons>
  FEATURE

  def learning_page_mylessons_feature(data)
    webiva_feature(:learning_page_mylessons) do |c|
      c.loop_tag('lesson') { |t| data[:modules] }
      c.link_tag('lesson:') { |t| t.locals.lesson.learning_module.page_url }
      c.value_tag('lesson:name') { |t| t.locals.lesson.learning_module.name }
    end
  end


  feature :learning_page_module_display, :default_feature => <<-FEATURE
  <cms:active>
    <cms:page_link>Goto your <cms:name/> program!</cms:page_link>
  </cms:active>
  <cms:not_active>
    <cms:page_link>Buy this program!</cms:page_link>
  </cms:not_active>
  
  
  FEATURE

  def learning_page_module_display_feature(data)
    webiva_feature(:learning_page_module_display) do |c|
      c.expansion_tag('active') { |c| data[:lusr] }
      c.value_tag('name') { |c| data[:mod].name }
      c.link_tag('active:page') { |c| data[:options].active_page_url }
      c.link_tag('not_active:page') { |c| data[:options].inactive_page_url }
    end
  end


  feature :learning_page_lesson_list, :default_feature => <<-FEATURE
    <cms:started>
      <cms:section>
        <b><cms:name/></b><br/>
        <cms:lesson>
          <cms:active>
            <cms:lesson_link><cms:short_title/></cms:lesson_link>
          </cms:active>
          <cms:not_active>
            <cms:short_title/>
          </cms:not_active>
          <cms:not_last> | </cms:not_last>
        </cms:lesson>
        <br/><br/>
      </cms:section>
    </cms:started>
  FEATURE
  

  def learning_page_lesson_list_feature(data)
    webiva_feature(:learning_page_lesson_list) do |c|
      c.expansion_tag('started') { |t| data[:started] }
      c.loop_tag('started:section') { |t| t.attr['reverse'] ? data[:sections].reverse : data[:sections] }
        c.attribute_tags('started:section',%w(name)) { |t| t.locals.section }
        c.loop_tag('section:lesson') { |t| lessons = t.locals.section.learning_lessons.find(:all,:order => 'learning_lessons.position');  t.attr['reverse'] ?  lessons.reverse : lessons }
        c.attribute_tags('started:section:lesson',%w(title short_title)) { |t| t.locals.lesson }
        c.link_tag('started:section:lesson') { |t| data[:page_url] + "/" + t.locals.lesson.id.to_s }
        c.expansion_tag('section:lesson:active') { |t|  data[:lusr].active_lesson?(t.locals.lesson) }
        
    end
  end
  feature :learning_page_lesson, :default_feature => <<-FEATURE
    <cms:started>
      <h4><cms:user:first_name/>'s Go Bag Program</h4>
      <h1><cms:title/></h1>
      <cms:goal index='1'>
        <div>Todays step goal is <cms:value/></div>
      </cms:goal>
      <cms:goal index='0'>
        <div>Todays water goal is <cms:value/> bottles</div>
      </cms:goal>
      <cms:media width='420' height='280' />
      <cms:no_media><cms:image/></cms:no_media>
      <br/>
      <cms:content/>
    </cms:started>
    <cms:not_started>
      Welcome to your online learning course!
      
      
      <cms:start_button>Start my program</cms:start_button>
    </cms:not_started>
  FEATURE
  
  
  

  def learning_page_lesson_feature(data)
    webiva_feature(:learning_page_lesson) do |c|
      c.expansion_tag('started') { |t| data[:started] }
      c.attribute_tags('started',%w(title)) { |t| data[:lesson] }
      c.user_tags('user') { |t| data[:user] }
      c.value_tag('goal') { |t| data[:lesson].goals[t.attr['index'].to_i] }
      c.image_tag('image') { |t| data[:lesson].image_file }
      c.value_tag('media') do |tag| 
      
        med = data[:lesson].media_file
        tag.locals.entry = data[:lesson]
        if med
          ext = med.extension.to_s.downcase
          
          case ext
          when 'mp3'
            width = (tag.attr['width'] || 420).to_i
           "<div id='learning_media_#{tag.locals.entry.id}'></div>
            <script>
              var so = new SWFObject('/components/learning/javascripts/jw_player/mp3player.swf','mpl','#{width}','20','7');
              so.addVariable('file','#{med.url}');
              so.addVariable('playlist','false');
              so.addVariable('autostart','false');
              so.write('learning_media_#{tag.locals.entry.id}');
            </script>"
          when 'flv'
           width = (tag.attr['width'] || 420).to_i
           height = (tag.attr['height'] || 280).to_i
           "<div id='learning_media_#{tag.locals.entry.id}'></div>
            <script>
              var so = new SWFObject('/components/learning/javascripts/jw_player/mediaplayer.swf','mpl','#{width}','#{height}','7');
              so.addVariable('file','#{med.url}');
              so.addVariable('autostart','false');
              so.write('learning_media_#{tag.locals.entry.id}');
            </script>"
          else
            "<a href='#{med.url}'>Download Media</a>"
          end
        else
          nil
        end
        
      end      
      c.value_tag('content') do |tag| 
        media_files = data[:lesson].image_list_arr
        tag.locals.entry = data[:lesson]
        txt = data[:lesson].content_html.to_s.gsub(/\%\%MEDIA([0-9]+)(,([0-9]+)x([0-9]+)){0,1}\%\%/) do |mtch|
          file_id = media_files[$1.to_i-1]
          med = DomainFile.find_by_id(file_id)
          if med
          ext = med.extension.to_s.downcase
          
          case ext
          when 'mp3'
            width = ($3 || 420).to_i
           "<div id='learning_media_#{tag.locals.entry.id}_#{$1}'></div>
            <script>
              var so = new SWFObject('/components/learning/javascripts/jw_player/mp3player.swf','mpl','#{width}','20','7');
              so.addVariable('file','#{med.url}');
              so.addVariable('playlist','false');
              so.addVariable('autostart','false');
              so.write('learning_media_#{tag.locals.entry.id}_#{$1}');
            </script>"
          when 'flv'
           width = ($3 || 420).to_i
           height = ($4 || 280).to_i
           "<div id='learning_media_#{tag.locals.entry.id}_#{$1}'></div>
            <script>
              var so = new SWFObject('/components/learning/javascripts/jw_player/mediaplayer.swf','mpl','#{width}','#{height}','7');
              so.addVariable('file','#{med.url}');
              so.addVariable('autostart','false');
              so.write('learning_media_#{tag.locals.entry.id}_#{$1}');
            </script>"
          else
            "<a href='#{med.url}'>Download</a>"
          end
        else
          ''
        end
        end
        
        txt
      end
      
      c.post_button_tag('not_started:start_button') { |t| '?learning=start' }
    end
  end

  feature :learning_page_tracking, :default_feature => <<-FEATURE
    <cms:graph/><br/>
    <cms:form>
    <h4>Track your Steps:</h4>
    <cms:field size='10'/><cms:submit>Go</cms:submit><br/>
    <cms:when/>
    </cms:form>
    <br/>
    
  FEATURE
  
  def learning_page_tracking_feature(data)
    webiva_feature(:learning_page_tracking) do |c|
      c.value_tag('graph') { |t| "<div style='height:190px'>" + data[:graph] + "</div>" }
      c.form_for_tag('form',:tracking, :html => { :onsubmit => "new Ajax.Updater(\"paragraph_#{paragraph.id}\",\"#{ajax_url}\",{ parameters: Form.serialize(this), evalScripts: true }); return false" }) { |t| TrackingModel.new({}) }
        c.form_field_tag('form:field')
        c.form_field_tag('form:when',:control => 'radio_buttons',:options =>data[:dates],:separator => ' ')
        c.submit_tag('form:submit', :onclick => 'this.disabled = true;')
    end
  end
  
  class TrackingModel < HashModel
    attributes :field => nil, :when => 0
    
    integer_options :when
    
  end
  
  

end
