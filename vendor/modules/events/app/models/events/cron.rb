

class Events::Cron


  def self.generate_events(tm)
  
    EventsRepeat.find(:all).each do |repeater|
      repeater.generate_events
    end
  
  end

end
