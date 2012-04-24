

class Calendar::IcalDispatcher < ModuleDispatcher
  

  available_pages ['/','ical','ical','ical',false]
                  
  
  def ical(args)
    simple_dispatch(1,'calendar/page','ical', :connections => { :input => [ :ical, args[0] ] } ) 
  end

end
