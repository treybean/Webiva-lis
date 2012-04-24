
class Rewards::ManageUserController < ModuleController
  permit 'rewards_manage'

  component_info 'Rewards'

  def self.members_view_handler_info
    {
      :name => 'Rewards',
      :controller => '/rewards/manage_user',
      :action => 'view'
    }
   end

  # need to include
  include ActiveTable::Controller
  active_table :transaction_table,
                RewardsTransaction,
                [ hdr(:options, :transaction_type, :options => :transaction_type_options),
                  :amount,
                  :used,
                  :note,
                  hdr(:static, 'Admin'),
                  :created_at,
                  :updated_at
                ]

  public

  def transaction_table(display=true)
    @user ||= EndUser.find params[:path][0]
    @rewards_user ||= RewardsUser.push_user @user.id
    @tab ||= params[:tab]

    active_table_action 'transaction' do |act,ids|
    end

    @active_table_output = transaction_table_generate params, :conditions => ['used = 1 && rewards_user_id = ?', @rewards_user.id], :include => :rewards_user, :order => 'updated_at DESC'

    render :partial => 'transaction_table' if display
  end

  def view
    @user = EndUser.find params[:path][0]
    @rewards_user = RewardsUser.push_user @user.id
    @tab = params[:tab]
    transaction_table(false)
    render :partial => 'view'
  end

  def transaction
    @user = EndUser.find params[:path][0]
    @rewards_user = RewardsUser.push_user @user.id
    @tab = params[:tab]
    @transaction = @rewards_user.rewards_transactions.build :admin_user_id => myself.id, :used => true

    if request.post? && params[:transaction]
      @transaction.attributes = params[:transaction]
      @transaction.note = "[Administrative %s]" / @transaction.transaction_type_display if @transaction.note.to_s.strip.blank?

      if params[:commit] && @transaction.save
        render :update do |page|
          page << 'RewardsData.viewTransactions();'
        end
        return
      end
    end

    render :partial => 'transaction'
  end

  protected

  def transaction_type_options
    RewardsTransaction.transaction_type_select_options
  end
end
