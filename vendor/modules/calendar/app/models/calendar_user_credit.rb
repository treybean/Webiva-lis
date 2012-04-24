
class CalendarUserCredit < DomainModel

  belongs_to :calendar_user
  belongs_to :end_user
  belongs_to :admin_user,:class_name => 'EndUser', :foreign_key =>'admin_user_id'
end
