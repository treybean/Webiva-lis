
class Events::EndUserExtension < DomainModelExtension

  def after_create(usr)
  
    credit_offset  = Events::AdminController.module_options.automatic_credit
    if credit_offset > 0
      EventsCreditType.find(:all,:conditions => { :id => 1 }).each do |ct|
        EventsUserCredit.credit_adjustment!(usr,ct.id,1,"Automatic Credit")
      end
    end
    true
  end  

end
