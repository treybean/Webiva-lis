

class LearningUser < DomainModel

  belongs_to :learning_module
  belongs_to :end_user
  
  belongs_to :last_lesson, :class_name => 'LearningLesson', :foreign_key => 'last_lesson_id'
  belongs_to :next_lesson, :class_name => 'LearningLesson', :foreign_key => 'next_lesson_id'
  
  has_many :learning_user_lessons
  
  has_one :learning_data_entry, :dependent => :destroy
  
  def reset_user!
    self.start_module!
  end
  
  def start_module!
    first_lesson = self.learning_module.first_lesson
    
    spacing = first_lesson.spacing_override_minutes.to_i > 0 ? first_lesson.spacing_override_minutes : (self.learning_module.spacing_minutes || 1440)
    
    self.update_attributes(
          :started => true, 
          :finished => false,
          :last_section_position => 1,
          :last_lesson_position => 1, 
          :last_lesson_id => first_lesson.id, 
          :last_lesson_at => Time.now,
          :next_lesson_at => Time.now + spacing.minutes)
  
  end
  
  # Advance to the next module but don't send an email
  def advance_module
    next_lesson = self.learning_module.next_lesson(self.last_lesson)
    
    if next_lesson && next_lesson.learning_section
      spacing = next_lesson.spacing_override_minutes.to_i > 0 ? next_lesson.spacing_override_minutes : (self.learning_module.spacing_minutes || 1440)
      self.update_attributes(
          :last_section_position => next_lesson.learning_section.position,
          :last_lesson_position => next_lesson.position, 
          :last_lesson_id => next_lesson.id, 
          :last_lesson_at => self.next_lesson_at,
          :next_lesson_at => Time.now + spacing.minutes,
          :lesson_viewed => false
        )
    else
      self.update_attributes(:finished => true)
    end
    
    self.reload
    next_lesson
  end
  
  include ActionView::Helpers::DateHelper
  
  def trigger_warning!(warning)
    vars = {}
    vars[:time] = distance_of_time_in_words(self.last_view_at,Time.now)
  
    case warning
    when :first
      self.learning_module.first_warning_template.deliver_to_user(self.end_user,vars)
      self.reload(:lock => true)
      self.update_attributes(:first_warning_triggered  => true)
    when :last
      self.learning_module.last_warning_template.deliver_to_user(self.end_user,vars)
      self.reload(:lock => true)
      self.update_attributes(:last_warning_triggered  => true)
    end
  end
  
  
  # Advance to the next module and send an email out as well
  def activate_module
    next_lesson = advance_module
    if next_lesson && self.learning_module.email_template
      vars = next_lesson.attributes
      vars[:lesson_name] = next_lesson.title
      self.learning_module.email_template.deliver_to_user(self.end_user, vars )
    end
    next_lesson
  end
  
  def view_lesson(lesson,data = {})
    now = Time.now
    user_lesson = self.learning_user_lessons.find_by_learning_lesson_id(lesson.id) ||
                      self.learning_user_lessons.build(:learning_lesson_id => lesson.id,:learning_section_id => lesson.learning_section_id,:end_user_id => self.end_user_id)
    user_lesson.data ||= {}
    user_lesson.data.merge!(data)
    user_lesson.first_view_at ||= now
    user_lesson.views ||= 0
    
    user_lesson.update_attributes(:last_view_at => now,:views => user_lesson.views + 1)

    self.reload(:lock => true)
    self.last_view_at = now
    self.lesson_viewed = true
    self.first_warning_at = now + self.learning_module.first_warning_days.days
    self.last_warning_at = now + self.learning_module.last_warning_days.days
    self.save
  end
  
  def active_lesson?(lesson)
    return false unless self.last_section_position && self.last_lesson_position
    (self.last_section_position > lesson.learning_section.position) ||  (self.last_section_position == lesson.learning_section.position && self.last_lesson_position >= lesson.position)
  end
  
  def visible_sections
    self.learning_module.learning_sections.find(:all,:conditions => [ 'learning_sections.position BETWEEN ? AND ? AND visible=1',1,self.last_section_position ],:include => :learning_lessons)
  end
  
  
  def tracking
    self.learning_data_entry || self.create_learning_data_entry(:end_user_id => self.end_user_id)
  end
  
  def add_tracking_entry!(goal_number,date,value)
    tracking.add_entry!(goal_number,date,value)
  end
end
