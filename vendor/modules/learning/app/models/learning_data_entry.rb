

class LearningDataEntry < DomainModel
  belongs_to :learning_user
  belongs_to :end_user
  
  serialize :data
  
  
  def add_entry!(goal_number,date,value)
    setup_goal_data
    self.data[:goals][goal_number.to_i] ||= {}
    
    
    date = date.to_date if date.is_a?(Time)
    
    self.data[:goals][goal_number.to_i][date.to_date] = value
    self.save
  end
  
  def tracking_data(goal_number,count = 10)
    setup_goal_data
    tracking = (self.data[:goals][goal_number] || {}).to_a
    tracking.sort! { |a,b| a[0] <=> b[0] }
    back = count > tracking.length ? tracking.length : count

    tracking[-back..-1]
  end
  
  private
  
  def setup_goal_data
    self.data ||= {}
    self.data[:goals] ||= {}
  end

end
