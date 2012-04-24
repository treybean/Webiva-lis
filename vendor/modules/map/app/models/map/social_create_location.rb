
class Map::SocialCreateLocation < DomainModelExtension

  def after_save(social_unit)

    loc = MapLocation.find_by_locality_location_type_id(social_unit.id) || MapLocation.new(:locality_location_type_id => social_unit.id)

    loc.attributes = social_unit.attributes.slice('address','city','state','zip','name')
    loc.identifier = social_unit.url
    loc.active = true

    loc.save
  end

  def before_destroy(social_unit)
    loc = MapLocation.find_by_locality_location_type_id(social_unit.id)

    loc.destroy if loc
  end

end
