# frozen_string_literal: true

class Settings::IdentityProofsController < Settings::BaseController
  layout 'admin'

  before_action :authenticate_user!
  before_action :check_required_params, only: :new

  def index
    @proofs = AccountIdentityProof.where(account: current_account).order(provider: :asc, provider_username: :asc)
    @proofs.each(&:refresh!)
  end

  def new
    @proof = current_account.identity_proofs.new(
      token: params[:token],
      provider: params[:provider],
      provider_username: params[:provider_username]
    )

    render layout: 'auth'
  end

  def create
    @proof = current_account.identity_proofs.where(provider: resource_params[:provider], provider_username: resource_params[:provider_username]).first_or_initialize(resource_params)
    @proof.token = resource_params[:token]

    if @proof.save
      redirect_to @proof.on_success_path(params[:user_agent])
    else
      flash[:alert] = I18n.t('identity_proofs.errors.failed', provider: @proof.provider.capitalize)
      redirect_to settings_identity_proofs_path
    end
  end

  private

  def check_required_params
    redirect_to settings_identity_proofs_path unless [:provider, :provider_username, :token].all? { |k| params[k].present? }
  end

  def resource_params
    params.require(:account_identity_proof).permit(:provider, :provider_username, :token)
  end
end
