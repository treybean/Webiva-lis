
class Events::ProductBooking < Shop::ProductFeature

   def self.shop_product_feature_handler_info
    { 
      :name => 'Event Booking',
      :callbacks => [ :purchase, :stock ],
      :options_partial => "/events/handlers/product_booking"
    }
   end
   
   def purchase(user,order_item,session)
     evt = EventsEvent.find_by_id(@options.event_id)
     evt.book_user!(user,:no_credit => true)
     EventsUserCredit.credit_adjustment!(user,evt.events_credit_type_id,0,"Order #" + order_item.shop_order_id.to_s)
   end
   
   def stock(opts,user)
    booking = EventsBooking.find(:first,:conditions => { :events_event_id => @options.event_id,:end_user_id => user.id })
    evt = EventsEvent.find_by_id(@options.event_id)
    spaces = evt.event_spaces - evt.unconfirmed_bookings 
    
    (booking || spaces == 0) ? 0 : 1
   end

   def self.options(val)
    ProductBookingOptions.new(val)
   end
   
   class ProductBookingOptions < HashModel
    default_options :event_id => nil
    
    integer_options :event_id
   end
   
   
   def self.description(opts)
    opts = self.options(opts)
     evt = EventsEvent.find_by_id(opts.event_id)
    sprintf("Event Booking: (%s)",evt ? evt.name : 'Missing Event');
   end
   
end
