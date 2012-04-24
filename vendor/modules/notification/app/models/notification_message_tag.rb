
class NotificationMessageTag < DomainModel
  belongs_to :notification_message
  belongs_to :tag

  validates_presence_of :notification_message_id
  validates_presence_of :tag_id
end
