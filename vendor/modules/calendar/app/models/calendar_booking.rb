class CalendarBooking < DomainModel

  belongs_to :calendar_slot

  attr_accessor :verify_availability, :apply_credits, :admin_user_id
  
  validates_presence_of :booking_on,:calendar_slot_id
  validates_numericality_of :start_time, :end_time
  
  belongs_to :end_user
  
  has_options :duration, 
                    [[ '15 Minutes', 15],
                     [ '30 Minutes', 30],
                     [ '45 Minutes',45],
                     [ '1 Hour',60],
                     [ '1 Hour 15 Minutes',75],
                     [ '1 Hour 30 Minutes',90],
                     [ '1 Hour 45 Minutes',105],
                     [ '2 Hours',120],
                     [ '2 Hour 15 Minutes',135],
                     [ '2 Hour 30 Minutes',150],
                     [ '2 Hour 45 Minutes',165],
                     [ '3 Hours',180],
                     [ '3 Hour 15 Minutes',195],
                     [ '3 Hour 30 Minutes',210],
                     [ '3 Hour 45 Minutes',225],
                     [ '4 Hours',240]
                     
                     ]  
  
  def duration=(val)
    @duration = val
  end
  
  def duration
    self.end_time.to_i - self.start_time.to_i
  end
  
  def before_validation
    if @duration
      self.end_time = self.start_time + @duration.to_i
    end
  end

  
  def validate
    if self.recipient_name.blank? && self.end_user_id.blank?
      self.errors.add(:recipient_name,'must be entered')
    end
    
    if (self.verify_availability.is_a?(Array) && self.verify_availability.include?('verify')) || self.verify_availability == true
      
      # use calendar_slot_id_before_type_cast b/c it might be a group instead of an individual slot
      if(cal_slot = Calendar::Utility.availability?(self.calendar_slot_id_before_type_cast,self.booking_on,self.start_time,self.end_time))
        self.calendar_slot_id = cal_slot[0] 
      else
        self.errors.add(:booking_on, 'are not currently available')
      end
    end
    
    if (self.apply_credits == 'verify' || self.apply_credits == 'apply') && !self.end_user
      self.errors.add(:recipient_name, 'does not have a member account to apply credits to, please create a member account or select "Dont\'t use credits"')
    end
    
    if self.apply_credits == 'verify' && self.end_user
      cu = CalendarUser.user(self.end_user)
      self.errors.add(:recipient_name, 'does not have enough credits') if cu.credits < 1
    end
  end
  
  def before_create
    if self.end_user
      self.recipient_name = self.end_user.name
    end
  end
  
  def after_create
    if !self.apply_credits.blank? && self.apply_credits != 'off' && self.end_user
      CalendarUser.update_credits(self.end_user,-1,"Admin Booking:" + self.time_description, :admin_user_id => self.admin_user_id)
    elsif confirmed? && self.admin_user_id  && self.end_user
      CalendarUser.update_credits(self.end_user,0,"Admin Booking (No Credits):" + self.time_description, :admin_user_id => self.admin_user_id)
    elsif !confirmed? && !self.admin_user_id  && self.end_user
      CalendarUser.update_credits(self.end_user,0,"Added to Cart (Unconfirmed):" + self.time_description)
    end 
  end
  


  def get_color
    Calendar::Utility.options.booking_color
  end
  
  def time
    sprintf("%s to %s".t,Calendar::Utility.time_str(self.start_time),Calendar::Utility.time_str(self.end_time))
  end
  
  def to_time
    self.booking_on.to_time + self.start_time.minutes
  end
  
  def to_end_time
    self.booking_on.to_time + self.end_time.minutes
  end
  
  def time_description
    self.to_time.strftime(DEFAULT_DATETIME_FORMAT.t)
  end
  

  # Shop Functions
  def get_description(start_at=nil,end_at=nil,options = {})
    # ignore the start_at and end_at for bookings
    dsc = (self.confirmed? ? "" : "(UNCONFIRMED) ") + sprintf("%s booked with %s on %s from %s to %s".t,self.recipient_name,self.calendar_slot ? (options[:override] || self.calendar_slot.name) : 'Unknown', self.booking_on.strftime(DEFAULT_DATE_FORMAT.t),
                  Calendar::Utility.time_str(self.start_time),Calendar::Utility.time_str(self.end_time)) 
    
    dsc += "\n (" + self.description + ')' unless self.description.blank?
    dsc
  end
  
  def name
    Calendar::Utility.options.booking_name + " " + self.booking_on.strftime("%A %m/%d/%Y".t)
  end
  
  def cart_details(options,cart)
    # ignore the start_at and end_at for bookings
    dsc = sprintf("%s to %s".t,
                  Calendar::Utility.time_str(self.start_time),Calendar::Utility.time_str(self.end_time))
    dsc
  end

  def cart_shippable?
    false
  end
  
  def cart_sku
    Calendar::Utility.options.booking_name + self.booking_on.strftime("-%m-%d-%Y".t)
  end

  
  def cart_price(options,cart)
    currency = cart.currency
    user = cart.user
    opts = Calendar::Utility.options
    
    if self.end_user && opts.member_classes.include?(self.end_user.user_class_id.to_s)
      opts.member_price.to_f
    else
      opts.nonmember_price.to_f
    end
  end
  
  def cart_limit(options,cart)
    if !self.confirmed? && (self.valid_until > Time.now || Calendar::Utility.booking_availability?(self))
      1
    else
      0
    end
  end  
  
  def cart_post_processing(user,order_item,session)
    self.update_attributes(:confirmed => true,:valid_until => nil)
    if(session[:calendar] &&
       session[:calendar][:booking_ids]) 
      session[:calendar][:booking_ids].delete(self.id)
      CalendarUser.update_credits(user,0,"Purchased Booking:" + self.time_description, :shop_order_id => order_item.shop_order_id )
      
    end
  end 
  
  
end
