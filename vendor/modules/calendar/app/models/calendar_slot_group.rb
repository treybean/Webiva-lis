class CalendarSlotGroup < DomainModel

validates_presence_of :name

has_many :calendar_slots, :dependent => :destroy


end
