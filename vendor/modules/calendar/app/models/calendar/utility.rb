class Calendar::Utility

  def self.generate_day(date)
    { :start => date, :end => date, :days => [ [ { :date => date.clone } ] ] }
  end

  def self.generate_visible_days(start_month,start_year)
  
    start_date = Time.local(start_year,start_month,1)
    
    # get the day of the week
    dow = start_date.wday
    
    # get the sunday prior to the start of the month
    calendar_start = start_date - dow.days
    
    eom = start_date.end_of_month
    
    calendar_end = (eom + (6-eom.wday).days).midnight
    
    # return start / end and a two dimensional array of [week][day of week] (0 indexed)
    output = { :start => calendar_start, :end => calendar_end, :days => [] }
    
    date = calendar_start
    day = 0
    week = 0
    while date <= calendar_end do
      output[:days][week] ||= []
      output[:days][week] << { :date => date.clone }
      day+=1
      week += 1 if day % 7 == 0
      date = (date.tomorrow + 2.hours).at_beginning_of_day
    end
    
    output
  end
  
  def self.generate_visible_day(date)
    output = { :start => date.clone, :end => date.clone, :days => [ [ { :date => date.clone } ]]  }
  end
  
  def self.generate_calendar(visible_days)
    date_index = {}
    
    visible_days[:days].each do |week|
      week.each do |day|
        date_index[day[:date]] = day
      end
    end
    availabilities = CalendarAvailability.find(:all,
                :conditions => ['start_on <= ? AND (end_on IS NULL OR end_on >= ?)',visible_days[:end].to_date,visible_days[:start].to_date ],
                :include => :calendar_slot)
    now = Time.now.at_beginning_of_day 
    start_day = (visible_days[:start] < now) ? now : visible_days[:start]

    availabilities.each do |av|
      av.between(start_day,visible_days[:end]) do |day|
        day = day.at_midnight
        date_index[day][:slots] ||= {}
        date_index[day][:slots][av.calendar_slot_id] ||= {}
        date_index[day][:slots][av.calendar_slot_id][:av] ||= []
        date_index[day][:slots][av.calendar_slot_id][:av] << [ av.start_time,av.end_time, av]
      end
    end
    
    # Get holidays
    holidays = CalendarHoliday.find(:all,
                :conditions => ['start_on <= ? AND (end_on IS NULL OR end_on >= ?)',visible_days[:end].to_date,visible_days[:start].to_date ],
                :include => :calendar_holiday_slots)
    holidays.each do |holiday|
      holiday.between(start_day,visible_days[:end]) do |day|
        holiday.calendar_holiday_slots.each do |slot|
          date_index[day][:slots] ||= {}
          date_index[day][:slots][slot.calendar_slot_id] ||= {}
          date_index[day][:slots][slot.calendar_slot_id][:hol] ||= []
          date_index[day][:slots][slot.calendar_slot_id][:hol] << [ holiday.start_time,holiday.end_time, holiday ]
        end
      end
    end
    
    # Get Bookings
    bookings = CalendarBooking.find(:all,:include => :calendar_slot,
                :conditions => ['(booking_on BETWEEN ? AND ?) AND (confirmed=1 OR valid_until > NOW())',visible_days[:start].to_date,visible_days[:end].to_date ])
    bookings.each do |booking|
      booking_on = booking.booking_on.to_time
      date_index[booking_on][:slots] ||= {}
      date_index[booking_on][:slots][booking.calendar_slot_id] ||= {}
      date_index[booking_on][:slots][booking.calendar_slot_id][:book] ||= []
      date_index[booking_on][:slots][booking.calendar_slot_id][:book] << [ booking.start_time,booking.end_time, booking ]
    end

    visible_days[:days]
  end
  
  # For each day, generate an ordered array of blocks,
  # With the starting time and the 
  def self.generate_blocks(weeks)
    opts = self.options
    start_availability = Time.now + opts.booking_ahead_hours.hours
  
    weeks.each do |week|
      week.each do |day|
        if(day[:slots]) 
          day[:slots].each do |slot_id,day_data|
            block = Calendar::BooleanBlock.new()
            mins_diff = ((start_availability - day[:date].at_midnight)/60).floor
            
            block.add(day_data[:av]) if day_data[:av]
            block.remove(day_data[:hol]) if day_data[:hol]
            block.remove(day_data[:book]) if day_data[:book]
            
            block.remove([[0,mins_diff,CalendarHoliday.new()]]) if mins_diff > 0
            
            
            day[:slots][slot_id] = block.to_a
          end
        end
      end
    end
  
    weeks
  end
  
  def self.clear_bookings(weeks)
    weeks.each do |week|
      week.each do |day|
        if(day[:slots]) 
          day[:slots].each do |slot_id,day_data|
            day[:slots][slot_id] = day_data.find_all() { |blk| blk[3] }
          end
        end
      end
    end
  
    weeks  
  end
  
  def self.group_slots(weeks)
    weeks.each do |week|
      week.each do |day|
        if(day[:slots]) 
          block = Calendar::BooleanBlock.new()
          day[:slots].each { |slot_id,day_data| block.join(day_data)  }
          day[:slots] = { 0 => block.to_a   }
        else
          day[:slots] = { 0 => [] }
        end
      end
    end
    weeks
  end
  
  
  def self.add_bookings(weeks,user)
  
    date_index = {}
    
    weeks.each do |week|
      week.each do |day|
        date_index[day[:date]] = day
      end
    end
  
    start_date = weeks[0][0][:date]
    end_date = weeks[-1][-1][:date]
    bookings = CalendarBooking.find(:all,
                :conditions => ['(booking_on BETWEEN ? AND ?) AND (confirmed=1 OR valid_until > NOW()) AND end_user_id = ?',start_date.to_date,end_date.to_date,user.id ]).group_by(&:booking_on)
                
    bookings.each do |booking_date,bookings|
      booking_blocks = bookings.collect { |booking| [ booking.start_time,booking.end_time, booking ] }
      day = date_index[booking_date.to_time]
      day[:slots].each do |slot_id,day_data|
        block = Calendar::BooleanBlock.new()
        block.add(day_data)
        block.remove(booking_blocks)
        
        day[:slots][slot_id] = block.to_a
      end
    end
    
    weeks
        
  end
  
  def self.overlap?(block0,block1) 
    return (block0[0] >= block1[0] && block0[1] <= block1[1]) ||
          (block0[0] < block1[0] && block0[1] > block1[0]) ||
          (block0[0] < block1[1] && block0[1] > block1[1]) 
  
  end
  
  def self.booking_availability?(booking)
    self.availability?(booking.calendar_slot_id,booking.booking_on,booking.start_time,booking.end_time,booking.id) ? true : false
  end
  
  def self.availability?(calendar_slot_id,booking_on,start_time,end_time,calendar_booking_id=nil)
    if calendar_slot_id.to_s =~ /^Group([0-9]+)$/
      slot_group = CalendarSlotGroup.find_by_id($1)
      if slot_group
        slots = slot_group.calendar_slots
      else
        slots = []
      end
    else
      slots = [ calendar_slot_id.to_i ]
    end
    cur_time = Time.now
    unconfirmed_slot_id = nil
    
    available_slot_ids = []
    
    slots.each do |slot|
      slot = CalendarSlot.find_by_id(slot) if slot.is_a?(Integer)
      next unless slot
      
      availability = slot.has_availability?(booking_on,start_time,end_time)
      next unless availability # try next slot if there aren't availabilities
      
      holidays = CalendarHoliday.find(:first,
        :conditions => ['start_on <= ? AND (end_on IS NULL OR end_on >= ?) AND 
                       ( (start_time >= ? AND start_time < ?) OR (end_time > ? AND end_time <= ?) OR (start_time <= ? AND end_time >= ? ) )  AND
                          calendar_holiday_slots.calendar_slot_id = ?',
                        booking_on.to_date,booking_on.to_date,start_time,end_time,start_time,end_time,start_time,end_time, slot.id ],
        :include => :calendar_holiday_slots)
      next if holidays # try next slot if there are holidays in the way
     
      # Get all bookings, trying not to overwrite unconfirmed bookings if possible.
      bookings = slot.calendar_bookings.find(:all,
       :conditions => ['booking_on = ? AND 
                       ( (start_time >= ? AND start_time < ?) OR (end_time > ? AND end_time <= ?) OR (start_time <= ? AND end_time >= ? ) ) AND calendar_bookings.id != ?',
                        booking_on.to_date,start_time,end_time,start_time,end_time,start_time,end_time,calendar_booking_id || 0])
             
    
      valid_booking = nil
                 
      bookings.each do |booking|
        valid_booking = true if booking.confirmed || booking.valid_until > cur_time
      end
      next if valid_booking # try the next slot if there are any bookings in the way
      
      # if we made to here, we're good to go, slot is available at the suggested time
      # But lets do our best not to overwrite an unconfirmed slot by check the remaining slots
      # for full availability
      if bookings.length == 0
        available_slot_ids << slot.id
      elsif unconfirmed_slot_id.blank?
        unconfirmed_slot_id = slot.id
      end
    end
    
    
    # Return the unconfirmed slot id if we have nothing else
    # otherwise we will return nil
    if available_slot_ids.length > 0
      return available_slot_ids
    elsif unconfirmed_slot_id
      return [ unconfirmed_slot_id ]
    else
      return nil
    end
  end
  
  def self.signup_blocks(day,options = {}) 
      block_minutes = options[:block_minutes] || 60
      signup_length = options[:signup_length] || 60
      day_start_time = options[:start_time] || 0
      day_end_time = options[:end_time] || 60*24
      group = options[:group]
      
      if group
        slot_blocks = []
        (day[:slots]||[]).each do |slot_id,slot_data|
          slot_blocks += slot_data
        end
        slot_blocks.sort! { |a,b| a[0] <=> b[0] }
        day[:slots] = { 0 => slot_blocks }
      end
      
      day[:blocks] = []
      cur_time = day_start_time
      while cur_time < day_end_time
        day[:blocks] << [ cur_time,cur_time + block_minutes]      
        cur_time += block_minutes
      end
      
      day[:slots] ||= {}
      blocks = []
      overlap_blocks = []
      day[:slots].each do |slot_id,slot_data|
      
      # For each slot
        block_index = 0
        # Go through each time block,
        # Get the current block
        current_block = slot_data[block_index]
        cur_time = day_start_time
        blocks = []
        while cur_time < day_end_time
          cur_time_end = cur_time + signup_length.to_i
          
          starting_block = current_block
          starting_block_index = block_index
          block=nil
          # loop through all the blocks while we don't have a block,
          # or we only have an availability block,
          # and the starting block we are looking at is still within the scope
          while (!block || (block && block[3])) && starting_block && starting_block[0] < cur_time_end
          
            # if the current block has enough time
            if !starting_block[3] && self.overlap?(starting_block,[cur_time,cur_time_end])
              # if we overlap with a booking
              
              # check to see if the actual time overlaps or just the block time 
              if self.overlap?(starting_block,[cur_time,cur_time+block_minutes])
                block = [cur_time,cur_time+signup_length,starting_block[2],starting_block[3]]
              else
                block = [cur_time,cur_time+signup_length,nil,false]
              end
              overlap_blocks << [ starting_block, [cur_time,cur_time_end] ]
            elsif starting_block[3] && starting_block[0] <= cur_time && starting_block[1] >= cur_time_end
              # Add the block
              block = [cur_time,cur_time+signup_length,starting_block[2],starting_block[3]]
            end
            starting_block_index += 1
            starting_block = slot_data[starting_block_index]
          end
          
          if !block
            block = [cur_time,cur_time+block_minutes,nil,false]
          end
          
          
          # Check if we are looking at the wrong block
          while current_block && current_block[1] < cur_time
            if block_index < slot_data.length - 1
              block_index += 1 
              current_block = slot_data[block_index]
            else
              current_block = nil
            end
          end
          
          blocks << block
          cur_time += block_minutes
        end
        #raise overlap_blocks.inspect
        day[:slots][slot_id] = blocks
      end
      day
  end
  
  def self.format_block(blocks,total_width,total_height)
    opts = self.options
    unit_height = (total_height-2).to_f / (opts.end_time - opts.start_time).to_f
    all_slot_ids = CalendarSlot.find(:all,:order => 'name').map(&:id)
    blocks.each do |week|
      week.each do |day|
        if day[:slots]
          slot_offset=0
          slot_width = (total_width.to_f / day[:slots].length.to_i).floor.to_i

          day_slot_list =  day[:slots].keys
          slot_list = all_slot_ids.select { |slt| day_slot_list.include?(slt) }
          slot_list += day_slot_list - all_slot_ids
          
          slot_list.each do |slot_id|
            slot = day[:slots][slot_id]

#          day[:slots].each do |slot_id,slot|
            if slot
              day[:slots][slot_id] = slot.collect do |block|
                { :x => slot_offset * slot_width,
                  :width => slot_width,
                  :y => (unit_height * (block[0] - opts.start_time)).floor,
                  :height => (unit_height * (block[1] - block[0])).ceil,
                  :color => block[2].get_color,
                  :description => block[2].get_description(block[0],block[1], :override => 'Trainer')
                }
              end
            else
              day[:slots][slot_id] = []
            end            
            slot_offset += 1
          end
        end
      end
    end  
    
  end
  
  def self.options(val = nil )
    Configuration.get_config_model(CalendarOptions,val)
  end
  
  class CalendarOptions < HashModel
    default_options :start_time => 360, :end_time => 1080, :booking_color => "#ffff00", :event_color => "#ff0000", :block_minutes => 30, :signup_minutes => 60, :slot_name => 'Slot', :booking_name => 'Booking', :booking_ahead_hours => 24, :member_classes => [], :member_price => 75, :nonmember_price => 90
    
    integer_options :start_time, :end_time, :block_minutes, :signup_minutes, :booking_ahead_hours, :member_price,:nonmember_price 
    
    validates_presence_of :start_time,:end_time, :booking_color, :event_color
  
  end  
  
  def self.find_best_slot(user,slot_ids)
    # Find the most recent booking - try to make it not with the same person 2 times in a row
    recent = CalendarBooking.find(:first,:conditions => ['end_user_id=?',user.id],:order => 'created_at DESC')
    
    recent = recent.calendar_slot_id if recent
    
    min = nil
    
    # Go through each slot and find the people we have had the least with
    slot_ids = slot_ids.collect do |slot_id|
      cnt = CalendarBooking.count(:all,:conditions => ['end_user_id=? AND calendar_slot_id=?',user.id,slot_id]) + slot_id == recent.to_i ? 10 : 0
      min = cnt if !min || cnt < min
      [ slot_id, cnt ]
    end
    
    
    available = slot_ids.find_all { |a| a[1] == min }
    
    if available.length > 0
      available[rand(available.length)][0]
    else
      slot_ids[0]
    end
  end
  

  def self.time_str(offset,fmt = nil)
    # ( Time.now.at_midnight + offset * 60).strftime((fmt||"%I:%M %p").t)
    (Time.mktime(2008,01,01).at_midnight + 1.days + offset * 60).strftime((fmt||"%I:%M %p").t)
  end
end
