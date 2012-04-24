
class Map::Utility

  def self.options(val = nil )
    Configuration.get_config_model(Options,val)
  end
  
  class Options < HashModel
    default_options :api_key => nil, :locations_name => 'Locations'
    
    validates_presence_of :api_key  
  end  
  
  
end
