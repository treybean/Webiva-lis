class CalendarSlot < DomainModel

  validates_presence_of :name
  belongs_to :calendar_slot_group
  
  has_many :calendar_availabilities, :dependent => :destroy
  has_many :calendar_bookings, :dependent => :destroy

  def before_save
    generate_hash if self.slot_hash.blank?
  end

 def generate_hash
     letters = '123456789ACEFGHKMNPQRSTWXYZ'.split('')
     unique = false
     sec = Time.now.sec
     while(!unique)
      num = (0..24).to_a.collect { |n| letters[(rand(20000) + sec) % letters.length] }.join
      unique = true unless CalendarSlot.find_by_slot_hash(num)
     end
     self.slot_hash = num
  end    
  
  
  def has_availability?(booking_on,start_time,end_time)
      availabilities = self.calendar_availabilities.find(:all,
        :conditions => ['start_on <= ? AND (end_on IS NULL OR end_on >= ?) AND start_time <= ? AND end_time >= ?',
                        booking_on.to_date,booking_on.to_date,start_time,end_time ])

      availabilities.each do |availability|
        if availability.first_date(booking_on) == booking_on
          return availability
        end
      end
      return nil
  end
end
