

class LearningUserLesson < DomainModel
  serialize :data
  
  belongs_to :learning_lesson
  belongs_to :learning_section
end
