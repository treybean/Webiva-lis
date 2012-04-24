
class LearningSection < DomainModel

  belongs_to :learning_module
  has_many :learning_lessons, :order => 'learning_lessons.position', :dependent => :destroy
 
  
  def before_create
    self.position = self.class.maximum(:position, :conditions => { :learning_module_id => self.learning_module_id }).to_i + 1
  end  

end
