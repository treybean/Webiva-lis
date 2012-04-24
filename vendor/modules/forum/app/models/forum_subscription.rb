class ForumSubscription < DomainModel
  belongs_to :end_user
  belongs_to :forum_topic
  belongs_to :forum_forum

  validates_presence_of :end_user_id, :forum_topic_id, :forum_forum_id
  validates_uniqueness_of :end_user_id, :scope => :forum_topic_id

  named_scope( :user_subscriptions, Proc.new { |user|
    {
      :conditions => { :end_user_id => user.id }
    }
  })

  def subscribe
    return @subscribe if @subscribe
    @subscribe = self.id ? true : false
  end

  def subscribe=(s)
    @subscribe = s
  end

  def subscribed?
    self.id ? true : false
  end
end
