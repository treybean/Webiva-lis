

class EventsUserCreditEntry < DomainModel
  belongs_to :events_credit_type
  belongs_to :end_user
  
  validates_presence_of :events_credit_type_id
  

  belongs_to :admin_user, :class_name => 'EndUser'
end
