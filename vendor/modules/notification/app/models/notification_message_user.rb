
class NotificationMessageUser < DomainModel
  belongs_to :end_user
  belongs_to :notification_message

  validates_presence_of :end_user_id
  validates_presence_of :notification_message_id

  def excerpt
    self.notification_message ? self.notification_message.excerpt : nil
  end
end
