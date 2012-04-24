
class Map::LocationController < ModuleController

  component_info 'map'

  include ActiveTable::Controller
  
  active_table :location_table, MapLocation,
                [ ActiveTable::IconHeader.new('',:width => 10),
                  ActiveTable::StringHeader.new("map_locations.name",:label => 'Name'),
                  ActiveTable::StringHeader.new("map_locations.city",:label => 'City'),
                  ActiveTable::StringHeader.new("map_locations.state",:label => 'State'),
                  ActiveTable::StringHeader.new("map_locations.zip",:label => 'Zip'),
                  ActiveTable::StringHeader.new("map_locations.contact_name",:label => 'Contact'),
                  ActiveTable::BooleanHeader.new("map_locations.active",:label => 'Act'),
                  ActiveTable::BooleanHeader.new("map_locations.lon IS NOT NULL",:label => 'Loc')
                 ]
                 
  cms_admin_paths 'content',
                  'Content' => { :controller => '/content' },
                  'Map Locations' => { :action => 'index' }
                  
                  
  def display_location_table(display = true) 
    active_table_action 'location' do |action,location_ids|
      MapLocation.delete(location_ids) if action == 'delete'
    end
  
    @tbl = location_table_generate params, :order => 'city, name'
    
    
    render :partial => 'location_table' if display
  
  end

  def index
    cms_page_path ['Content'],Map::Utility.options.locations_name
    display_location_table(false)
  end
  
  def edit
    @location = MapLocation.find_by_id(params[:path][0]) || MapLocation.new(:active => true)
    cms_page_path ['Content',[Map::Utility.options.locations_name,url_for({ :action => 'index' })]], @location.id ? [ 'Edit %s',nil,@location.name ] : 'Create'
    
    require_js('cms_form_editor')
    
    if request.post? && @location.update_attributes(params[:location])
      redirect_to :action => 'index' 
    end
    
  end


  def download
    
    output = ''
    CSV::Writer.generate(output) do |csv|
      csv << [ 'Name','Address','Address 2','City','State','Zip','Phone','Fax','Website','Description','Contact Name','Contact Email','Active' ]
      
      @locations  = MapLocation.find(:all,:order => '`state`,name')
      
      @locations.each do |c|
        csv << [ c.name,
                 c.address,
                 c.address_2,
                 c.city,
                 c.state,
                 c.zip,
                 c.phone,
                 c.fax,
                 c.website,
                 c.description,
                 c.contact_name,
                 c.contact_email,
                 c.active? ? 'Yes' : 'No'
                 ] 
      end
    end
    
    
    send_data(output,
      :stream => true,
      :type => "text/csv",
      :disposition => 'attachment',
      :filename => sprintf("%s_%d.%s","Locations",Time.now.strftime("%Y_%m_%d"),'csv')
      )
        
  end

end
