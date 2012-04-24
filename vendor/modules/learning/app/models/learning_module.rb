

class LearningModule < DomainModel


  has_many :learning_lessons, :order => 'learning_lessons.position'
  has_many :learning_sections, :order => 'learning_sections.position'
  has_many :learning_users
  
  serialize :goals
  
  belongs_to :email_template, :class_name => 'MailTemplate',:foreign_key => 'email_template_id'
  belongs_to :first_warning_template, :class_name => 'MailTemplate',:foreign_key => 'first_warning_template_id'
  belongs_to :last_warning_template, :class_name => 'MailTemplate',:foreign_key => 'last_warning_template_id'
  
  
  def before_save
    
  
  end
  
  def goal_text
    (self.goals || []).join("\n")
  end
  
  def goal_text=(val)
    self.goals = val.split("\n").map { |e| v = e.strip; v.blank? ? nil : v }.compact
  end
  
  
  def module_user(end_user)
    LearningUser.find_by_end_user_id_and_learning_module_id(end_user.id,self.id)
  end
  
  def create_module_user(end_user)
    LearningUser.create(:end_user_id => end_user.id, :learning_module_id => self.id)
    if !self.activation_tags.blank?
       end_user.tag_names_add(self.activation_tags) unless self.activation_tags.blank?
    end
  end
  
  def first_lesson
    first_section = self.learning_sections.first
    first_section.learning_lessons.first
  end
  
  def next_lesson(lesson)
    pos = lesson.position
    if next_less = lesson.learning_section.learning_lessons.find(:first,:conditions => ["position > ?",pos],:order => "position")
      next_less
    else
      sec_pos = lesson.learning_section.position
      if self.learning_sections.count > sec_pos
        next_section = learning_sections[sec_pos]
        next_section.learning_lessons[0]
      else
        nil
      end
    end
      
    
  
  end
  
end
