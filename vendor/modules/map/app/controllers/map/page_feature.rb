
class Map::PageFeature < ParagraphFeature
  

  feature :map_display, :default_feature => <<-FEATURE
    <div align='center'>
      <cms:map/>
      <cms:location_view>
        <cms:search_form>
        Search by <cms:search_by />
        <cms:search_by_zip>
          Zipcode: <cms:zip/>
          <cms:within/>
        </cms:search_by_zip>
        <cms:search_by_state>
          Select state: <cms:state/>
        </cms:search_by_state>
        <cms:search_by_details>
          <cms:details/>
        </cms:search_by_details>
        <cms:button>Search</cms:button>
        <cms:active_search><cms:clear_search/></cms:active_search>
        </cms:search_form>
        <cms:search_description>Searching locations <cms:value/></cms:search_description>
        <cms:locations>
          <table width='100%'>
          <cms:location>
          <tr>  
            <td>
              <cms:marker_link><cms:name/></cms:marker_link><br/>
              <cms:address/><br/>
              <cms:city/> <cms:state/>, <cms:zip/><br/>          
            <td>
            <cms:distance>
              <td align='right'>
                <cms:value/> Miles
              </td>
            </cms:distance>
          </tr>
          </cms:location>
          </table>
          <cms:pages/>
        </cms:locations>
        <cms:no_locations>
          <div>No Results</div>
        </cms:no_locations>
      </cms:location_view>
    </div>
  FEATURE
  
  
  def map_display_feature(data) 
    webiva_feature(:map_display) do |c|
       c.expansion_tag("location_view") {data[:options].display_type == 'locations'  }
       c.define_value_tag('map') do |tag| 
         if data[:options].display_type != 'locations' ||  data[:locations].length > 0
            "<a name='map_display'></a><div id='map_view_#{data[:paragraph].id}' style='width:#{data[:options].width}px; height:#{data[:options].height}px; overflow:hidden;'></div>"
         end
       end
       c.form_for_tag('search_form','search') { |t| data[:search] }
          c.field_tag('search_form:search_by',:control => 'select', :options => [['Zipcode','zip'],['State','state'],['Details','details']],
                        :onchange => %w(zip state details).map { |elm| "document.getElementById('search_by_#{elm}_#{paragraph.id}').style.display = this.value == '#{elm}' ? '' : 'none';" }.join(" ") )
          
          c.define_tag('search_form:search_by_zip') do |t|
            hidden = data[:search].search_by == 'zip' ? '' : 'style="display:none;"'
            "<span id='search_by_zip_#{paragraph.id}' #{hidden}>" + t.expand.to_s + "</span>"
          end
              c.field_tag('search_form:zip',:size => 10) 
              c.field_tag('search_form:within',:control => 'select', :options => data[:distance_options])
          
          c.define_tag('search_form:search_by_state') do |t|
            hidden = data[:search].search_by == 'state' ? '' : 'style="display:none;"'
            "<span id='search_by_state_#{paragraph.id}' #{hidden}>" + t.expand.to_s + "</span>"
          end
              c.field_tag('search_form:state',:control => 'select', :options => ([['-State-',nil]] + ContentModel.state_select_options)) 
          
          
          c.define_tag('search_form:search_by_details') do |t|
            hidden = data[:search].search_by == 'details' ? '' : 'style="display:none;"'
            "<span id='search_by_details_#{paragraph.id}' #{hidden}>" + t.expand.to_s + "</span>"
          end
              c.field_tag('search_form:details',:size => 20) 
          
          
          c.value_tag('search_description') do |t|
            if data[:searching]
              case data[:search].search_by 
              when 'zip'
                "within #{data[:search].within} miles of '#{h data[:search].zip}'"
              when 'details'
                "containing the term '#{h data[:search].details}'"
              when 'state'
                "in the state of #{h data[:search].state}"
              end
            else
              nil
            end
          end
          
          c.expansion_tag('active_search') { |t| data[:searching] || data[:state_search] }
          c.button_tag('search_form:clear_search',:name => 'clear',:value => 'Clear Search')
          c.button_tag('search_form:button')
       c.loop_tag('location') { |t| data[:locations] }
        define_location_tags(c)
        c.link_tag('location:marker') { |t|  { :href => '#map_display', :onclick => "MapEngine.activateMarker(#{t.locals.location.id});" } }
        c.pagelist_tag('locations:pages') { data[:pages] } 
        c.value_tag("state_search") { data[:state_search] }
          c.value_tag("state_search:results") { |t| data[:locations].length }
        c.expansion_tag("searching") { data[:searching] }
          c.value_tag("searching:results") { |t| data[:locations].length }
          c.value_tag("location:distance") { |t| t.locals.location.distance } 
     end
  end
  
  feature :map_page_location_detail, :default_feature => <<-FEATURE
    <cms:location>
      <cms:name><cms:value/><br/></cms:name>
      <cms:address/><br/>
      <cms:city/> <cms:state/>, <cms:zip/><br/>
    </cms:location>
    
  FEATURE
  
  def map_page_location_detail_feature(data)
    webiva_feature(:map_page_location_detail) do |c|
      c.expansion_tag("location") { |t| t.locals.location = data[:location] }
       define_location_tags(c)
    end  
  end
  
  def define_location_tags(c)
      c.attribute_tags("location", %w(name address address_2 city state zip phone fax identifier lon lat contact_name contact_email)) { |t| t.locals.location } 
      c.link_tag("location:website") { |t| t.locals.location.website }
      c.value_tag("location:description") { |t| h(t.locals.location.description.to_s).gsub("\n","<br/>")  }
      c.value_tag("location:description_html") { |t| t.locals.location.description_html }
    c.value_tag("location:overview_html") { |t| t.locals.location.description_html }
    c.value_tag("location:id") { |t| t.locals.location.id }
  end

  feature :map_page_zip_search, :default_feature => <<-FEATURE
<cms:search_form>
Search by zipcode: <cms:zip/><cms:submit/>
<cms:searching>
  <cms:zip>
    Showing results for <cms:city/>
   </cms:zip>
   <cms:no_results>
      Could not find a zipcode by that name
   </cms:no_results>
</cms:searching>
</cms:search_form>

FEATURE

  def map_page_zip_search_feature(data)
    webiva_feature(:map_page_zip_search) do |c|
      c.form_for_tag('search_form','search') { |t| data[:search] }
      c.field_tag('search_form:zip',:size => 10) 
      c.button_tag('search_form:submit')
      c.expansion_tag('searching') {  |t| data[:searching] }
      
      c.expansion_tag('searching:no_results') { |t| data[:no_results]}
      c.expansion_tag('searching:zip') { |t| t.locals.zip = data[:zip]}

      c.attribute_tags('searching:zip',%W(zip city state latitude longitude timezone dst country))  { |t| t.locals.zip }

    end
  end
  
end
