class Map::PageController < ParagraphController 

  editor_header 'Map Paragraphs'

  editor_for :map_view, :name => 'Map View', 
                          :feature => 'map_display',
                          :inputs => [ [ :data, 'Map Data', :map_data ],
                                       [ :callback, 'Map Callback', :map_callback ] ]                                       
  
  editor_for :location_detail, :name => "Location Detail",
                          :feature => 'map_page_location_detail',
                          :inputs => [ [ :location_id, 'Location ID',:path],
                                       [ :location_identifier, 'Location Identifier', :path ]] 
  
  editor_for :zip_search, :name => 'Zip Code Search',  :feature => 'map_page_zip_search',
                         :outputs => [ [ :state, 'State Output', :path ], [ :state_integer, "State Output (Integer)",:integer]]

  user_actions :map_details_view
  
  def map_view
    @options = MapViewOptions.new(params[:map_view] || paragraph.data || {})
    return if handle_module_paragraph_update(@options)
    
    @content_models = ContentModel.find_select_options(:all)
    
    if(@options.content_model_id.to_i > 0)
      @fields = ContentModelField.find_select_options(:all,:conditions => { :content_model_id => @options.content_model_id, :field_type => 'string' } )
      @text_fields = ContentModelField.find_select_options(:all,:conditions => { :content_model_id => @options.content_model_id, :field_type => 'text' } )
    end       
    
  end
  
  class MapViewOptions < HashModel
    attributes :width => 400, :height => 400, :display_type => 'connection', :show_map_types => 'yes',:show_zoom => 'full', :default_icon => nil, :default_zoom => nil, :content_model_id => nil,:content_model_field_id => nil, :content_model_response_field_id => nil, :detail_page_id => nil, :shadow_icon => nil, :icon_anchor_x => 0, :icon_anchor_y => 0, :info_anchor_x => 0,:info_anchor_y => 0,:show_all_locations => false, :per_page => 20, :center_via_google => false
    
    integer_options :content_model_id,:content_model_field_id, :content_model_response_field_id, :default_icon, :shadow_icon, :icon_anchor_x, :icon_anchor_y, 
                    :info_anchor_x, :info_anchor_y, :per_page
    boolean_options :show_all_locations, :center_via_google
    
    page_options :detail_page_id
    
    def validate
      if self.display_type == 'content_model'
        errors.add(:content_model_field_id,'is missing') if !content_model_id.blank? && content_model_field_id.blank?
        errors.add(:content_model_response_field_id,'is missing') if !content_model_id.blank? && content_model_response_field_id.blank?
      end
    end
  end
  
  
  class LocationDetailOptions < HashModel
    
  end

  class ZipSearchOptions < HashModel

  end
  
  def map_details_view
    paragraph = PageParagraph.find_by_id_and_display_type(params[:path][0],'map_view')
    
    options = MapViewOptions.new(paragraph.data || {})

    mdl = ContentModel.find(options.content_model_id)
    fld = mdl.content_model_fields.find(options.content_model_field_id)
    @resp_field = mdl.content_model_fields.find(options.content_model_response_field_id)
    
    @page = (params[:page] || 0).to_i
    
    @count = mdl.content_model.count(:all,:conditions => [ "`#{fld.field}` = ? AND `#{@resp_field.field}` != ''",params[:identifier] ])

    if(@page >= @count) 
      @page = @count-1
    end
    
    @responses = mdl.content_model.find(:all,:conditions => [ "`#{fld.field}` = ? AND `#{@resp_field.field}` != ''",params[:identifier] ],:offset => @page,:limit => 1, :order => "`#{mdl.table_name}`.id DESC")
    @response = @responses[0] 
    
    
    render :partial => 'map_details_view'
  end  
end
  
  
