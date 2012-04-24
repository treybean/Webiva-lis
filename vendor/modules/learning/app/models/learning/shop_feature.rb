
class Learning::ShopFeature < Shop::ProductFeature

   def self.shop_product_feature_handler_info
    { 
      :name => 'Activate Learning Module',
      :callbacks => [ :purchase, :stock ],
      :options_partial => "/learning/handlers/shop_feature"
    }
   end
   
   def purchase(user,order_item,session)
     mod = LearningModule.find_by_id(options.learning_module_id)
     lusr = mod.create_module_user(user)
     
     redirect_to options.redirect_page_url if options.redirect_page_url
   end
   
  def stock(opts,user)
    mod = LearningModule.find_by_id(options.learning_module_id)
    lusr = mod.module_user(user)
    
    if lusr
      0
    else
      1
    end
   end
   

   def self.options(val)
    LearningFeatureOptions.new(val)
   end
   
   class LearningFeatureOptions < HashModel
    default_options :learning_module_id => nil,:redirect_page_id => nil
    
    page_options :redirect_page_id
    integer_options :learning_module_id
    validates_numericality_of :learning_module_id
   end
   
   
   def self.description(opts)
    opts = self.options(opts)
    mod = LearningModule.find_by_id(opts.learning_module_id) || LearningModule.new
    sprintf("Learning Module (%s)",mod.name);
   end
   
end
