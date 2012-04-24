

class Learning::Cron


  def self.activate_lessons(tm)
  
    if tm.hour == 3
      LearningModule.find(:all).each do |mod|
        mod.learning_users.find(:all,:conditions => 'finished = 0 AND next_lesson_at < NOW() AND lesson_viewed = 1').each do |usr|
          usr.activate_module
        end
        
        if mod.first_warning_template
          mod.learning_users.find(:all,:conditions => 'finished = 0 AND first_warning_at < NOW() AND first_warning_triggered = 0').each do |usr|
            usr.trigger_warning!(:first)
          end
        end
        
        if mod.last_warning_template
          mod.learning_users.find(:all,:conditions => 'finished = 0 AND last_warning_at < NOW() AND last_warning_triggered = 0').each do |usr|
            usr.trigger_warning!(:last)
          end
        end
      end
    
    else
      LearningModule.find(:all,:conditions => 'hourly = 1').each do |mod|
        mod.learning_users.find(:all,:conditions => 'finished = 0 AND next_lesson_at < NOW() AND lesson_viewed = 1').each do |usr|
          usr.activate_module
        end
        
       if mod.first_warning_template
          mod.learning_users.find(:all,:conditions => 'finished = 0 AND first_warning_at < NOW() AND first_warning_triggered = 0').each do |usr|
            usr.trigger_warning!(:first)
          end
       end
         
       if mod.last_warning_template
          mod.learning_users.find(:all,:conditions => 'finished = 0 AND last_warning_at < NOW() AND last_warning_triggered = 0').each do |usr|
            usr.trigger_warning!(:last)
          end
       end
          
     end
    end
  
  end

end
