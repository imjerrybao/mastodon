# frozen_string_literal: true

class ActivityPub::InboxesController < Api::BaseController
  include SignatureVerification

  before_action :set_account

  def create
    if signed_request_account
      upgrade_account
      process_payload
      head 201
    else
      head 202
    end
  end

  private

  def set_account
    @account = Account.find_local!(params[:account_username])
  end

  def body
    @body ||= request.body.read
  end

  def upgrade_account
    return unless signed_request_account.subscribed?
    Pubsubhubbub::UnsubscribeWorker.perform_async(signed_request_account.id)
  end

  def process_payload
    ActivityPub::ProcessingWorker.perform_async(signed_request_account.id, body.force_encoding('UTF-8'))
  end
end
