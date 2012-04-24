require 'maruku'

class LearningLesson < DomainModel

  belongs_to :learning_module
  belongs_to :learning_section
  acts_as_list :scope => :learning_section_id
  
  belongs_to :media_file, :class_name => 'DomainFile'
  belongs_to :image_file, :class_name => 'DomainFile'
  
  serialize :data
  
  
  def before_create
    self.position = self.class.maximum(:position, :conditions => { :learning_section_id => self.learning_section_id }).to_i + 1
  end
  
  def before_save
    generate_content_html
    generate_email_html
  end
  
  def image_list_arr
    self.image_list.to_s.split(",").select { |elm| !elm.blank? }
  end
  

  
  def generate_content_html
     begin ## Throw away
       txt = self.image_substitute(self.content)
      self.content_html = Maruku.new(txt).to_html
    rescue
      self.content_html = 'Invalid Markdown'.t
    end  
  end
  
  
  def generate_email_html
     begin ## Throw away
      txt = self.image_substitute(self.email_content)
      self.email_content_html = Maruku.new(txt).to_html
    rescue
      self.email_content_html = 'Invalid Markdown'.t
    end  
  end
  
  
  
  def image_substitute(content)
    html = content.gsub(/\!\[([^\]]+)\]\(([^"')]+)/) do |mtch|
      alt_text = $1
      full_url = $2
      image_path,size = full_url.strip.split("::")
      if image_path =~ /^http(s|)\:\/\//
        url = full_url
      else
        df = DomainFile.find_by_file_path("/" + image_path)
        url = Configuration.domain_link(df ? df.url(size) : "/images/spacer.gif")
      end
      "![#{alt_text}](#{url}"
    end
  end
  
  def options
    self.data ||= {}  
  end
  
  def goals
    options[:goals] || []
  end
  
  def goals=(val)
    options[:goals] = val
  end
    

end
