
class Calendar::BookingCreditPack < Shop::ProductFeature

   def self.shop_product_feature_handler_info
    { 
      :name => 'Booking Credit Pack',
      :callbacks => [ :purchase ],
      :options_partial => "/calendar/handlers/booking_credit_pack"
    }
   end
   
   def purchase(user,order_item,session)
      # Add the necessary amount of credits
      CalendarUser.update_credits(user,options.credits.to_i,"Credit Pack Purchase:" + options.credits.to_s,:shop_order_id => order_item.shop_order_id)
   end

   def self.options(val)
    CreditPackOptions.new(val)
   end
   
   class CreditPackOptions < HashModel
    default_options :credits => nil
    
    integer_options :credits
    validates_numericality_of :credits, :greater_than => 0
   end
   
   
   def self.description(opts)
    opts = self.options(opts)
    sprintf("Booking Credit Pack (%d)",opts.credits);
   end
   
end
