
class Map::PageRenderer < ParagraphRenderer
  module_renderer
  
  paragraph :map_view
  paragraph :location_detail
  paragraph :zip_search
  
  features 'map/page_feature'
  
  def map_view
  
    if editor?
     render_paragraph :text => 'Map not shown in Editor'
     return
    end
    module_options = Map::Utility.options
    options = paragraph_options(:map_view)
  
    connection_type,connection_data = page_connection
    
    if options.display_type == 'connection'

      if !connection_data
        render_paragraph :nothing => true
        return
      end
      if connection_type == :map_data
        obj = connection_data[0].find_by_id(connection_data[1])
        
        if !obj
          render_paragraph :nothing => true
          return
        end
        data = obj.map_data
        
        if !data[:markers] || data[:markers].length == 0
          render_paragraph :nothing => true
          return
        end
      else connection_type == :callback
        callback,data_func = connection_data
        data = data_func.call
        data[:callback] = callback
      end
    elsif options.display_type == 'content_model'
      data = get_content_model_data(paragraph.id,options.content_model_id,options.content_model_field_id,options.content_model_response_field_id)
    else
      @search = SearchForm.new(params[:clear] ? {} : params[:search])
      if request.post? && params[:search] && @search.valid?
        if @search.search_by == 'state' 
          @locations = MapLocation.state_search(@search.state)
          @state_search = @search.state
          @searching = true
        elsif @search.search_by == 'zip'
          @searching = true
          @locations = MapLocation.zip_search(@search.zip.to_s.gsub(" ",""),@search.within)
        elsif @search.search_by == 'details'
          @locations = MapLocation.details_search(@search.details)
          @searching = true
        end
        @pages = { :pages => 1 }
        
        data = MapLocation.location_data(@locations)
      else
        @pages,@locations = MapLocation.paginate(params[:page],:conditions => { :active => true },:order => 'name',:per_page => options.per_page)
        
        data = MapLocation.location_data(options.show_all_locations ? MapLocation.find(:all,:conditions => { :active => true }) : @locations)
      end
      
    end
  
    
    require_js('prototype')
    header_html("<script src=\"http#{'s' if request.ssl?}://www.google.com/jsapi\"></script>") if options.center_via_google

    header_html("<script src=\"http#{'s' if request.ssl?}://maps.google.com/maps?file=api&v=2&key=#{module_options.api_key}\" type=\"text/javascript\"></script>")     
    dist_options = [ ['Within 50 Miles',50], ['Within 25 Miles',25], ['Within 10 Miles',10], ['Within 5 Miles',5] ] 
    feature_data = { :paragraph => paragraph, :options =>  options, :distance_options => dist_options, :search => @search, :state_search => @state_search, :locations => @locations, :searching => @searching, :pages => @pages }

    feature_output = map_display_feature(feature_data)
    render_paragraph :partial => '/map/page/map_view', :locals => {
          :paragraph => paragraph, 
          :options =>  options, 
          :in_editor => editor?, 
          :searching => @searching,
          :data => data, 
          :feature_output => feature_output,
          :detail_url => options.detail_page_url.to_s }
  end
  
  class SearchForm < HashModel
    attributes :within => 100, :zip => '', :state => nil, :search_by => 'zip', :details => ''
    
    def validate
      if self.state.blank? && self.zip.blank? && self.details.blank?
        self.errors.add(:zip,'is missing')
      end
    end
    
    integer_options :within
  end
  
  
  def location_detail
  
    conn_type,conn_id = page_connection
    if conn_type == :location_id
      @loc = MapLocation.find_by_id_and_active(conn_id,true)
    elsif conn_type == :location_identifier
      @loc = MapLocation.find_by_identifier_and_active(conn_id,true)
    end
  
    data = { :location => @loc}
    render_paragraph :text => map_page_location_detail_feature(data)
  end

  def zip_search
    @search = SearchForm.new(params[:clear] ? {} : params[:search])

    if request.post? && params[:search]
      
      @zip = MapZipcode.find_by_zip(@search.zip)
      if @zip
        set_page_connection(:state,@zip.state)
        set_page_connection(:state_integer,@zip.state)
      else
        @no_results = true
      end

      
      @searching = true

    end

    render_paragraph :text => map_page_zip_search_feature
    
  end
  
  protected
  
  def get_content_model_data(paragraph_id,content_model_id,field_id,response_field_id)
    mdl = ContentModel.find(content_model_id)
    fld = mdl.content_model_fields.find(field_id)
    resp_field = mdl.content_model_fields.find(response_field_id)

    bounds = { :lat_min => 1000, :lat_max => -1000, :lon_min => 1000, :lon_max => -1000 }

    map_responses = MapZipcode.find(:all,:joins => "LEFT JOIN `#{mdl.table_name}` ON (`#{mdl.table_name}`.`#{fld.field}` = map_zipcodes.zip)",:conditions => "`#{mdl.table_name}`.id IS NOT NULL AND `#{mdl.table_name}`.`#{resp_field.field}`!=''",:limit => 1000,:group => 'zipcode',:order => "MAX(`#{mdl.table_name}`.id) DESC").collect do |resp|
                      bounds[:lat_min] = resp.latitude if resp.latitude < bounds[:lat_min]
                      bounds[:lat_max] = resp.latitude if resp.latitude > bounds[:lat_max]
                      bounds[:lon_min] = resp.longitude if resp.longitude < bounds[:lon_min]
                      bounds[:lon_max] = resp.longitude if resp.longitude > bounds[:lon_max]
                      
                      { :lat => resp.latitude,
                        :lon => resp.longitude,  
                        :title => resp.zip,
                        :ident => resp.zip
                      }
                    end
    center = map_responses.length > 0 ? [  map_responses[0][:lat], map_responses[0][:lon] ] : nil
    { :zoom => 11,  :click => true, :center => center,  :markers => map_responses, :callback => { :controller => '/map/page', :action => "map_details_view", :path => [ paragraph_id ] } }
  end
  
end
