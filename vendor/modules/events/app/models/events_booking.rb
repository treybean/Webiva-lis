

class EventsBooking < DomainModel

  belongs_to :events_event
  belongs_to :end_user
  
  def self.find_booking(user,event)
    EventsBooking.find_by_events_event_id_and_end_user_id(event.id,user.id,:conditions => 'confirmed = 1')
  end
  
  
  def after_destroy
    if(self.events_event)
      self.events_event.cancel_booking!(self) if self.confirmed?
    end
  end
  
  def get_description(start_at=nil,end_at=nil)
    # ignore the start_at and end_at for bookings
    dsc = sprintf("on %s at %s",self.events_event.event_on.strftime(DEFAULT_DATE_FORMAT.t),self.events_event.start_time_display)
  end
  
  def name
    self.events_event.name
  end
  
  def cart_details(options,cart)
    sprintf("on %s at %s",self.events_event.event_on,self.events_event.start_time_display)
  end

  def cart_shippable?
    false
  end
  
  def cart_sku
    "CLASS#" + self.events_event.id.to_s
  end

  
  def cart_price(options,cart)
    user = cart.user
    currency = cart.currency
    if self.end_user && self.events_event.events_credit_type.member_classes && self.events_event.events_credit_type.member_classes.include?(self.end_user.user_class_id.to_s)
      if !self.events_event.member_cost_override.blank?
        self.events_event.member_cost_override
      else
        self.events_event.events_credit_type.member_cost
      end
    else
      if !self.events_event.cost_override.blank?
        self.events_event.cost_override
      else
        self.events_event.events_credit_type.standard_cost
      end
    end
  end
  
  def cart_limit(options,cart)
    if self.events_event && !self.confirmed? && (self.valid_until > Time.now)
      1
    else
      0
    end
  end
  
  
  
  def cart_post_processing(user,order_item,session)
    self.events_event.confirm_booking!(self)
  end   
end
