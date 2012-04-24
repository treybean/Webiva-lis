require 'maruku'
require 'open-uri'
require 'rexml/document'

class MapLocation < DomainModel
  validates_presence_of :name,:address,:city,:state
  
  belongs_to :image, :class_name => 'DomainFile', :foreign_key => 'image_id'
  belongs_to :icon_image, :class_name => 'DomainFile', :foreign_key => 'icon_image_id'
  
  attr_accessor :distance

  def images
    return @images if @images
    
    @images = self.image_list.to_s.split(",").find_all { |elm| !elm.blank? }.collect { |elm|
      DomainFile.find_by_id(elm)
    }.find_all { |elm| !elm.blank? }
  end
  
  def before_validation
    if self.name.blank?
      self.name = "#{self.address}, #{self.city} #{self.state}"
    end
  end
  
  def before_save
   self.state = self.state.to_s.upcase
   if identifier.blank?
      identifier_try_partial = name.downcase.gsub(/[ _]+/,"-").gsub(/[^a-z+0-9\-]/,"")
      idx = 2
      identifier_try = identifier_try_partial 
      
      while(MapLocation.find_by_identifier(identifier_try,:conditions => ['id != ?',self.id || 0] ))
        identifier_try = identifier_try_partial + '-' + idx.to_s
        idx += 1
      end
      
      self.identifier = identifier_try
    end
    
    if self.lon.blank? || self.lat.blank? || self.zip.blank?
      calculate_location
    end
    
    true
  end
  
  def full_address
    "#{self.address}, #{self.city}, #{self.state} #{self.zip}"
  end
  
  def calculate_location
    api_key=Map::Utility.options.api_key
    
    return if api_key.blank?
    
    xml=open("http://maps.google.com/maps/geo?q=#{CGI.escape(self.full_address)}&output=xml&key=#{api_key}").read
    doc=REXML::Document.new(xml)

    if doc.elements['//kml/Response/Status/code'].text != '200'
      return false
    else
      doc.root.each_element('//Response') do |response|
	      response.each_element('//Placemark') do |place|      
	        calc_lng,calc_lat=place.elements['//coordinates'].text.split(',')
	        
	        self.lat = calc_lat if self.lat.blank?
	        self.lon = calc_lng if self.lon.blank?
	        
	        self.zip = place.elements['//PostalCodeNumber'].text if self.zip.blank? && place.elements['//PostalCodeNumber']
	        
	        return true
	      end # end each place
      end # end each response
    end # end if result == 200
    return false
  end  
  
  def self.existing_location(opts)
    self.find(:first,:conditions => opts.slice(:address,:city,:state,:zip))
  end
  
  def self.location_data(locations)
     bounds = { :lat_min => 1000, :lat_max => -1000, :lon_min => 1000, :lon_max => -1000 }
    data= {  }
    data[:markers] = locations
    data[:markers].each do |loc|
        bounds[:lat_min] = loc.lat if loc.lat &&  loc.lat  < bounds[:lat_min]
        bounds[:lat_max] = loc.lat if loc.lat && loc.lat > bounds[:lat_max]
        bounds[:lon_min] = loc.lon if loc.lon && loc.lon < bounds[:lon_min]
        bounds[:lon_max] = loc.lon if loc.lon && loc.lon > bounds[:lon_max]      
    end
    
    data[:center] = [ (bounds[:lat_max] + bounds[:lat_min]) / 2,
                      (bounds[:lon_max] + bounds[:lon_min]) / 2 ]
    data[:bounds] = bounds
    data
  end
  
  def map_options
    opts = {}
    if self.icon_image
      opts.merge!({:icon_url =>  self.icon_image.url, :icon_width => self.icon_image.width, :icon_height => self.icon_image.height })
    end
    opts
  end
  
  def self.deg2rad(deg); deg.to_f * Math::PI / 180; end
  def self.rad2deg(rad); rad * 180 / Math::PI; end
  
  def self.state_search(state,opts={})
   locs = MapLocation.find(:all,
        { :conditions => ['map_locations.state=?',state ],
          :order => 'name'  }.merge(opts))
  end
  
  def self.zip_search(zip,max_dist,opts={})
  
    zipcode = MapZipcode.find_by_zip(zip)
    return [] unless zipcode
    
    # Order the pubs by distance
    locs = MapLocation.find(:all,
        { :select => "map_locations.*,
                    SQRT(POW(69.1 * (map_locations.lat - #{zipcode.latitude}), 2) + POW(69.1 * (map_locations.lon - #{zipcode.longitude}) * cos(#{zipcode.longitude}/57.3), 2)) as metric",
        :conditions => 'map_locations.active=1',
        :order => 'metric'  }.merge(opts))
        
    # Now calculate the actual distance in miles
    locs = locs.map do |loc|
    
     theta = zipcode.longitude - loc.lon.to_f
     dist = Math.sin(deg2rad(zipcode.latitude)) * Math.sin(deg2rad(loc.lat)) + 
            Math.cos(deg2rad(zipcode.latitude)) * Math.cos(deg2rad(loc.lat)) * Math.cos(deg2rad(theta))
     dist = Math.acos(dist)
     dist = rad2deg(dist)
     distance = dist * 60 * 1.1515 * 0.8684
     if distance > 10
       loc.distance = distance.round.to_s
     else
       loc.distance = sprintf("%1.1f",distance)
     end
     distance > max_dist ? nil : loc
    end.compact
  
    return locs
  end  
  
  
  def self.details_search(details)
    
    vals = []
    sql =  self.columns.map do |col|
      vals << "%#{details}%"
      "(`#{col.name}` LIKE ?)"
    end
  
    locs = MapLocation.find(:all,:conditions => [ "(" + sql.join(" OR ") + ")" ] + vals)
  
  end

end
