

class EventsCreditType < DomainModel

 validates_uniqueness_of :name
 
 validates_numericality_of :standard_cost,:member_cost

 has_many :events_events, :dependent => :nullify
 
 serialize :member_classes
 
end
