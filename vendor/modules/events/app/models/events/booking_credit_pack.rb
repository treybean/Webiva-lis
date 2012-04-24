
class Events::BookingCreditPack < Shop::ProductFeature

   def self.shop_product_feature_handler_info
    { 
      :name => 'Events Booking Credit Pack',
      :callbacks => [ :purchase ],
      :options_partial => "/events/handlers/booking_credit_pack"
    }
   end
   
   def purchase(user,order_item,session)
      # Add the necessary amount of credits
     EventsUserCredit.credit_adjustment!(user,options.events_credit_type_id,options.credits.to_i,"Credit Pack Purchase:" + options.credits.to_s,:shop_order_id => order_item.shop_order_id)
   end

   def self.options(val)
    CreditPackOptions.new(val)
   end
   
   class CreditPackOptions < HashModel
    default_options :credits => nil, :events_credit_type_id => nil
    
    integer_options :credits, :events_credit_type_id
    validates_numericality_of :credits, :greater_than => 0
    validates_numericality_of :events_credit_type_id
   end
   
   
   def self.description(opts)
    opts = self.options(opts)
    sprintf("Booking Credit Pack (%d)",opts.credits);
   end
   
end
