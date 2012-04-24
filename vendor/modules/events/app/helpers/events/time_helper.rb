

module Events::TimeHelper

  def time_generate(offset,start_date=nil)
    tm = (start_date||Time.now).at_midnight
    hours = (offset / 60.0).floor
    minutes = offset % 60
    Time.local(tm.year,tm.month,tm.day,hours,minutes)
  end

  def time_display(offset,fmt = nil)
    tm = Time.now.at_midnight
    hours = (offset / 60.0).floor
    minutes = offset % 60
    
    time_generate(offset).strftime((fmt||"%I:%M %p").t)
    
  end
  
  
  def time_calc(start_date,offset)
    time_generate(offset,start_date)
  end 
end
