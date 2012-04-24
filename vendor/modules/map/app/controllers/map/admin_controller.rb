class Map::AdminController < ModuleController
  
  permit 'map_config'
  
  component_info 'Map', :description => 'Map features', 
                              :access => :private
  cms_admin_paths "options",
                   "Options" =>   { :controller => '/options' },
                   "Modules" =>  { :controller => '/modules' },
                   "Map Options" => { :action => 'options' }

  
  content_model :locations
  
  register_handler :model, :end_user_address, "Map::AddressExtension", :actions => [ :before_save  ] 
  
  register_permission_category :map, "Map" ,"Map and Location Permissions"
  register_permissions :map, [ [ :config, 'Map Configuration', 'Can configure map module'],
                                [ :locations, 'View Map Locations']
                             ]
  

  register_handler :model, :social_unit, "Map::SocialCreateLocation", :actions => [ :after_save, :before_destroy ] 

  protected
  def self.get_locations_info
  
      [
      {:name => Map::Utility.options.locations_name,:url => { :controller => '/map/location' } ,:permission => 'map_locations', :icon => 'icons/content/map.gif' }
      ]
  end

  public                  
               
  def options
    cms_page_path ["Options","Modules"], "Map Options"

    @options = Map::Utility.options(params[:options])
      
      if request.post? && params[:options] && @options.valid?
        Configuration.set_config_model(@options)
        SiteModule.complete_module_initialization('map')
        flash[:notice] = 'Updated Map Options'
        cms_page_redirect "Modules"
      end
    end
  
  def import_zipcodes
    if MapZipcode.count(:all) == 0
      cnt =0  
      CSV.open("#{RAILS_ROOT}/vendor/modules/map/files/zipcodes.csv",'r') do |row|
        
        MapZipcode.connection.execute("INSERT INTO map_zipcodes (zip,city,state,latitude,longitude,timezone,dst,country) VALUES (#{row.collect { |val| MapZipcode.connection.quote(val) }.join(",")})")
        cnt += 1
      end
      cms_page_path ['Options','Modules','Map Options'], 'Imported Zipcodes'
      render :inline => "#{cnt} Zip codes imported", :layout => 'manage'
    else 
      redirect_to 'options'
    end
  end  
end
