class ForumForum < DomainModel

  validates_presence_of :name, :forum_category_id

  cached_content :identifier => :url, :update => [ :forum_category ]

  content_node_type :forum, "ForumTopic", :content_name => :name, :title_field => :subject

  belongs_to :forum_category
  has_many :forum_topics, :dependent => :destroy
  has_many :forum_posts
  has_many :forum_subscriptions

  belongs_to :image, :class_name => 'DomainFile'

  named_scope :main_forums, :conditions => 'forum_forums.main_page = 1'

  def before_validation
    self.url = generate_url(:url,self.name) if self.url.blank?
  end

  def content_filter
    self.forum_category.content_filter
  end

  def folder_id
    self.forum_category.folder_id
  end

  def allow_anonymous_posting
    self.forum_category.allow_anonymous_posting
  end

  def allow_attachments
    self.forum_category.allow_attachments
  end

  def allowed_to_create_post?(end_user)
    if self.forum_category.post_permission_granted?(end_user)
      (self.allow_anonymous_posting || (end_user && end_user.id)) ? true : false
    else
      false
    end
  end
  
  def content_admin_url(forum_topic_id)
    {  :controller => '/forum/posts', :action => 'list', :path => [ self.forum_category_id,self.id, forum_topic_id ] }
  end

  def content_type_name
    "Forum"
  end


  def allowed_to_create_topic?(end_user)
    self.allowed_to_create_post?(end_user)
  end

  def can_add_attachments_to_posts?
    self.forum_category.can_add_attachments_to_posts?
  end

  def upload_folder
    self.forum_category.upload_folder
  end

  def upload_folder_id
    self.forum_category.folder_id
  end

  def valid_file_size?(size)
    self.forum_category.valid_file_size?(size)
  end

  def subscription_template
    self.forum_category.subscription_template
  end
end
