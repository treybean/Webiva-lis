require  File.expand_path(File.dirname(__FILE__)) + "/../../rewards_spec_helper"
add_factory_girl_path(File.join(File.expand_path(File.dirname(__FILE__)),"..","..","..","..","shop","spec"))

describe Rewards::PageRenderer, :type => :controller do
  controller_name :page
  integrate_views

  reset_domain_tables :rewards_user, :rewards_transaction, :end_user, :end_user_cache
  reset_domain_tables :shop_products # MyISAM has no transactions
  transaction_reset

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/rewards/page/' + paragraph, options, inputs)
  end

  before do
    test_activate_module(:shop,:shop_currency => "USD")
  end

  before(:each) do
    @options = Rewards::AdminController.module_options :rewards_value => 10
    Configuration.set_config_model(@options)

    mock_user

    Shop::ShopShop.default_shop
    # Create a bunch of products form a couple different shops
    @products = (0..4).map { |n| Factory.create(:shop_product) }

  end

  describe "Redeem Paragraph" do
    before(:each) do
      @rnd = generate_page_renderer('redeem')
    end

    it "should render the redeem paragraph" do
      assert_difference 'RewardsUser.count', 1 do
        renderer_get @rnd
      end
    end

    it "should not add rewars to the cart" do
      @rewards_user = RewardsUser.push_user @myself.id
      @rewards_user.update_attributes :rewards => 1000

      assert_difference 'RewardsUser.count', 0 do
        assert_difference 'RewardsTransaction.count', 0 do
          renderer_post @rnd, :rewards => {:amount => 10}
        end
      end
    end

    it "should add rewards to the cart" do
      @rewards_user = RewardsUser.push_user @myself.id
      @rewards_user.update_attributes :rewards => 1000

      assert_difference 'Shop::ShopCartProduct.count' , 1 do
        @rnd.get_cart.add_product @products[0], 1
      end

      assert_difference 'RewardsUser.count', 0 do
        assert_difference 'RewardsTransaction.count', 1 do
          assert_difference 'Shop::ShopCartProduct.count', 1 do
            renderer_post @rnd, :rewards => {:amount => 10}
          end
        end
      end
    end

    it "should remove rewards from the cart" do
      @rewards_user = RewardsUser.push_user @myself.id
      @rewards_user.update_attributes :rewards => 1000

      @transaction = @rewards_user.rewards_transactions.create :amount => 0, :transaction_type => 'debit'
      @rnd.get_cart.add_product @products[0], 1
      @rnd.get_cart.add_product @transaction, 10

      assert_difference 'RewardsUser.count', 0 do
        assert_difference 'RewardsTransaction.count', -1 do
          assert_difference 'Shop::ShopCartProduct.count', -1 do
            renderer_post @rnd, :rewards => {:amount => 0}
          end
        end
      end
    end

    it "should add rewards and redirect" do
      success = SiteVersion.default.root.push_subpage 'success'
      @rnd = generate_page_renderer('redeem', {:success_page_id => success.id})

      @rewards_user = RewardsUser.push_user @myself.id
      @rewards_user.update_attributes :rewards => 1000

      @rnd.get_cart.add_product @products[0], 1
      renderer_post @rnd, :rewards => {:amount => 10}

      @rnd.should redirect_paragraph('/success')
    end
  end
end
