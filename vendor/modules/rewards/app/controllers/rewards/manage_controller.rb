
class Rewards::ManageController < ModuleController
  permit 'rewards_manage'

  component_info 'Rewards'

  cms_admin_paths 'content',
                  'Content'   => {:controller => '/content'},
                  'Rewards'   => {:action => 'users'}

  # need to include
  include ActiveTable::Controller
  active_table :user_table,
                RewardsUser,
                [ hdr(:static, 'User'),
                  :rewards,
                  :created_at,
                  :updated_at
                ]

  def user_table(display=true)
    active_table_action 'user' do |act,ids|
    end

    @active_table_output = user_table_generate params, :order => :updated_at

    render :partial => 'user_table' if display
  end

  def users
    cms_page_path ['Content'], 'Rewards'
    user_table(false)
  end

  active_table :transaction_table,
                RewardsTransaction,
                [ hdr(:static, 'User'),
                  :amount,
                  hdr(:options, :transaction_type, :options => :transaction_type_options),
                  :used,
                  :note,
                  hdr(:static, 'Admin'),
                  :created_at,
                  :updated_at
                ]

  def transaction_table(display=true)
    @user ||= RewardsUser.find(params[:path][0]) if params[:path][0]

    active_table_action 'transaction' do |act,ids|
    end

    conditions = @user ? ['used = 1 && rewards_user_id = ?', @user.id] : ['used = 1']
    @active_table_output = transaction_table_generate params, :conditions => conditions, :include => :rewards_user, :order => 'updated_at DESC'

    render :partial => 'transaction_table' if display
  end

  def transactions
    @user = RewardsUser.find(params[:path][0]) if params[:path][0]
    cms_page_path ['Content', 'Rewards'], @user ? '%s Transactions' / @user.end_user.name : 'All Transactions'
    transaction_table(false)
  end

  protected

  def transaction_type_options
    RewardsTransaction.transaction_type_select_options
  end
end
