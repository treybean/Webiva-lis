

class Events::CalendarFeature < ParagraphFeature


  include Events::PageRenderer::EventFeature

  feature :events_calendar_month_list, :default_feature => <<-FEATURE
    <div style='font-size:10px;'>
     <cms:calendar>
      <cms:previous><div style='float:left'><a <cms:href/> > &lt;&lt; Previous Month</a></div></cms:previous>
      <cms:next><div style='float:right'><a <cms:href/> > Next Month &gt;&gt;</a></div></cms:next>
      <div align='center'><cms:date/></div>
      <div style='clear:both;'></div>
      <table cellpadding='0' cellspacing='0'>
        <tr><cms:day_labels><td align='center'><cms:label/></td></cms:day_labels></tr>
        <cms:week><tr><cms:day><td><cms:display/></td></cms:day></tr></cms:week>
      </table>
    </cms:calendar>  
    </div>
  FEATURE
  
  
  @@day_labels = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday' ]
  @@day_labels_short = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
  @@day_labels_mini = ['S','M','T','W','T','F','S']
  

  def events_calendar_month_list_feature(data)
    webiva_feature(:events_calendar_month_list) do |c|
      c.define_expansion_tag('calendar') { |t| data[:calendar][:days] }
      
      
      c.define_tag('calendar:previous') { |tag| tag.expand }
      c.define_tag 'calendar:previous:href' do |tag|
        "href='#{site_node.node_path}/#{data[:previous_month]}' onclick='new Ajax.Updater(\"paragraph_#{paragraph.id}\",\"#{ajax_url}/#{data[:previous_month]}\"); return false;'"
      end
      
      c.define_tag('calendar:next') { |tag| tag.expand }
      c.define_tag 'calendar:next:href' do |tag|
        "href='#{site_node.node_path}/#{data[:next_month]}'  onclick='new Ajax.Updater(\"paragraph_#{paragraph.id}\",\"#{ajax_url}/#{data[:next_month]}\"); return false;'"
      end
      
      c.define_date_tag('calendar:date') do |tag|
        data[:date]
      end
      
      c.define_tag('calendar:day_labels') do |tag|
        labels = tag.attr['short'] ? @@day_labels_short : @@day_labels
        labels = tag.attr['mini'] ?  @@day_labels_mini : labels
        output = ''
        labels.each do |lbl|
          tag.locals.day_label = lbl.t
          output += tag.expand
        end
        output
      end
      
      c.define_tag('calendar:day_labels:label') { |tag| tag.locals.day_label }
      
      c.define_tag('calendar:week') do |t|
        c.each_local_value(data[:calendar][:days],t,'week')
      end
      
      c.define_tag('calendar:week:day') do |tag|
        c.each_local_value(tag.locals.week,tag,'day')
      end
      
      c.define_position_tags('calendar:week:day')
      
      c.define_tag('calendar:week:day:display') do |t|
        day = t.locals.day
       
        if t.attr['short']
          day_label = day[:date].day.to_s
        else
          day_label = "#{day[:date].strftime("%B") if day[:date].day == 1} #{day[:date].day}"
        end
        
        if t.attr['current']
          day_label ='' unless day[:date].month == @visible_month 
        else
          day_label = "<b>#{day_label}</b>" if day[:date].month == @visible_month  
        end
        
        info = '<br/>'
        (day[:events]||{}).each do |event|
          if t.attr['mini']
            event_name = '';
          else
            event_name = t.attr['short'] ? "#{h event[0].name}" : "#{h event[1].name}: #{h event[0].name}" 
          end
          if data[:options].overlay
            info +="<div class='month_list_event #{"month_list_event_private" if event[0].is_private?}' onclick='SCMS.remoteOverlay(\"#{data[:event_page_url]}/#{event[0].id}\");'>#{event_name}</div>"
          else
            info +="<div class='month_list_event #{"month_list_event_private" if event[0].is_private?}' ><a href='#{data[:event_page_url]}/#{event[0].id}'>#{event_name}</a></div>"
          
          end
        end
        
        <<-EOT
         <div  class='month_list_day' style='position:relative;height:auto !important; height:#{data[:block_height]}px; min-height:#{data[:block_height]}px; width:#{data[:block_width]}px;overflow:hidden;'>
            <div style='position:absolute; right:#{data[:block_width].to_i < 35 ? 1 : 4 }px;  top:#{data[:block_height].to_i < 35 ? 1 : 4 }px; z-index:10;'>#{day_label}</div>
            #{info}
         </div>
        EOT
      end
      
      define_event_tags(c,data)
    end
  end
  feature :events_calendar_upcoming_list, :default_feature => <<-FEATURE
    <cms:events>
      Upcoming Events
      <ul>
      <cms:event>
        <li><cms:detail_link><cms:name/></cms:detail_link> <cms:date/></li>
      </cms:event>
      </ul>
    </cms:events>
  FEATURE
  
   include Events::PageRenderer::EventFeature

  def events_calendar_upcoming_list_feature(data)
    webiva_feature(:events_calendar_upcoming_list) do |c|
      c.expansion_tag('admin') { |t| data[:add_events] }
        c.link_tag('admin:add') do |t|
          path =  "#{data[:detail_page_url]}/#{data[:target].id}/?edit=1"
          if data[:options].overlay
           { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}');" }
          else
            path 
          end
        end
      c.loop_tag('event') { |t| data[:events] }
        define_event_tags(c,data)
        c.define_link_tag('event:detail') do |t|
          if data[:options].target_type == 'all' 
            path =  "#{data[:detail_page_url]}/#{t.locals.event.id}"
          else
            path =  "#{data[:detail_page_url]}/#{data[:target].id}/#{t.locals.event.id}"
          end
          if data[:options].overlay
           { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}');" }
          else
            path 
          end
        end
        c.define_link_tag('event:edit')do |t| 
          path =  "#{data[:detail_page_url]}/#{data[:target].id}/#{t.locals.event.id}?edit=1"
          if data[:options].overlay
           { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}');" }
          else
            path 
          end
        end
    end
  end
  
  
  feature :events_calendar_event_detail, :default_feature => <<-FEATURE
   <cms:deleted>
     The event has been deleted
   </cms:deleted>
   <cms:event>
     <h2><cms:name/> <cms:edit_link>(Edit)</cms:edit_link></h2>
     <b> <cms:date/> <cms:start_time/>-<cms:end_time/></b>
     <cms:description/>
   </cms:event>
   <cms:edit>
    <cms:form>
      <cms:errors/>
      Name:<br/><cms:name/><br/>
      Description:<br/><cms:description/><br/>
      Date:<br/><cms:event_on/><br/>
      Start Time:<br/><cms:start_time/><br/>
      Duration:<br/><cms:duration/><br/>
      <cms:not_myself>
      Private Event:<br/><cms:private/><br/>
      </cms:not_myself>
      <cms:location>
        Address:<br/>
        <cms:address/><br/>
        City:<br/>
        <cms:city/><br/>
        State:<br/>
        <cms:state/><br/>
        Zip:<br/>
        <cms:zip/><br/>
      </cms:location>
      
      <cms:submit>Submit</cms:submit>
      <cms:delete>Delete</cms:delete>
    </cms:form>
   </cms:edit>
  FEATURE
  
  def events_calendar_event_detail_feature(data)
    webiva_feature(:events_calendar_event_detail) do |c|
      c.expansion_tag('deleted') { |t| data[:deleted] }
      c.expansion_tag('event') { |t| !data[:deleted] && !data[:edit] && t.locals.event = data[:event] }
      c.define_tag('no_event') { |t| !data[:deleted] && !data[:edit] && !data[:event] ? t.expand : nil }
      c.define_expansion_tag('myself') { |t| t.locals.event.target && t.locals.event_target == myself }
      c.define_expansion_tag('editor') { |t| data[:add_events] && t.locals.event.target}
        c.link_tag('editor:message') do |tag|
          { :href=> 'javascript:void(0);',
            :onclick => "SCMS.updateOverlay('#{data[:options].message_page_url}',{ page: 'write', partial: '1', 'recipient_id': '#{tag.locals.event.target.full_identifier}', 'message[subject]': '#{jvh tag.locals.event.name}', 'message[message]': '#{jvh tag.locals.event.description}'});"
          }
        end
c.link_tag('editor:text') do |tag|
          { :href=> 'javascript:void(0);',
            :onclick => "SCMS.updateOverlay('#{data[:options].text_page_url}',{ page: 'write', partial: '1', 'recipient_id': '#{tag.locals.event.target.full_identifier}', 'message[message]': '#{jvh tag.locals.event.name}: #{jvh tag.locals.event.description}'});"
          }
        end  
        
        # Whether this event has a target and a target of a certain type      
        c.define_expansion_tag('target_type') do |tag|
            if !tag.locals.event.target
              nil
            elsif tag.attr['type']
              target = tag.locals.event.target
              if target.class.to_s.underscore == tag.attr['type']
                if tag.attr['class']
                  cls = tag.locals.event.target.is_a?(EndUser) ? target.user_profile.name : target.class_name
                  cls == tag.attr['class'] ? true  : false
                else
                  true
                end
              else
                false
              end
            else
              true
            end
        end
        define_event_tags(c,data)
      c.link_tag('event:edit') do |c|
        if data[:add_events]
          if data[:options].overlay
            { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{paragraph_page_url}?edit=1');" }      
          else
            "#{paragraph_page_url}?edit=1"
          end
        else
          nil
        end
      end
      c.expansion_tag('edit') { |t| !data[:deleted] && data[:edit] }
        c.form_for_tag('edit:form',:event, :html => { :onsubmit => data[:options].overlay ? "SCMS.remoteOverlay('#{paragraph_page_url}?edit=1',Form.serialize(this) ); return false;" : nil }) { |t| data[:event] }
          c.field_tag('edit:form:name') 
          c.define_form_error_tag('edit:form:errors')
          c.field_tag('edit:form:description',:control => 'text_area', :cols => 40, :rows => 6)
          c.field_tag('edit:form:event_on',:control => 'date_field')       
          c.field_tag('edit:form:start_time',:control => 'select',:options =>  EventsEvent.time_select_options)       
          c.field_tag('edit:form:duration',:control => 'select',:options =>  EventsEvent.duration_select_options )    
          c.field_tag('edit:form:is_private', :control => "radio_buttons", :options => [['Yes',true],['No',false]] )
          c.expansion_tag('edit:form:new_event') { |t| data[:event].id.blank? }
          
           c.fields_for_tag('edit:form:location',:location) { |t| data[:location] }
            c.field_tag('edit:form:location:address')
            c.field_tag('edit:form:location:city')
            c.field_tag('edit:form:location:state',:size => 4)
            c.field_tag('edit:form:location:zip', :size => 8)
          c.expansion_tag('edit:myself') { |t| data[:event].target && data[:event].target == myself }
          c.button_tag('edit:form:submit')
          c.delete_button_tag('edit:form:delete')
          
    end
  end


end
