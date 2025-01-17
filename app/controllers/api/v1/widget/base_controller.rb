class Api::V1::Widget::BaseController < ApplicationController
  include SwitchLocale

  before_action :set_web_widget
  before_action :set_contact

  private

  def conversations
    if @contact_inbox.hmac_verified?
      verified_contact_inbox_ids = @contact.contact_inboxes.where(inbox_id: auth_token_params[:inbox_id], hmac_verified: true).map(&:id)
      @conversations = @contact.conversations.where(contact_inbox_id: verified_contact_inbox_ids)
    else
      @conversations = @contact_inbox.conversations.where(inbox_id: auth_token_params[:inbox_id])
    end
  end

  def conversation
    @conversation ||= conversations.last
  end

  def auth_token_params
    @auth_token_params ||= ::Widget::TokenService.new(token: request.headers['X-Auth-Token']).decode_token
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    @current_account = @web_widget.account
  end

  def set_contact
    @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(
      source_id: auth_token_params[:source_id]
    )
    @contact = @contact_inbox&.contact
    raise ActiveRecord::RecordNotFound unless @contact
  end

  def create_conversation
    ::Conversation.create!(conversation_params)
  end

  def inbox
    @inbox ||= ::Inbox.find_by(id: auth_token_params[:inbox_id])
  end

  def conversation_params
    # FIXME: typo referrer in additional attributes, will probably require a migration.
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        browser: browser_params,
        referer: permitted_params[:message][:referer_url],
        initiated_at: timestamp_params
      }
    }
  end

  def update_contact(email)
    contact_with_email = @current_account.contacts.find_by(email: email)
    if contact_with_email
      @contact = ::ContactMergeAction.new(
        account: @current_account,
        base_contact: contact_with_email,
        mergee_contact: @contact
      ).perform
    else
      @contact.update!(email: email, name: contact_name)
    end
  end

  def update_contact_phone(phone_number)
    contact_with_phone = @current_account.contacts.find_by(phone_number: phone_number)
    if contact_with_phone
      @contact = ::ContactMergeAction.new(
        account: @current_account,
        base_contact: contact_with_phone,
        mergee_contact: @contact
      ).perform
    elsif params[:contact].present? && params[:contact][:name].present?
      @contact.update!(phone_number: phone_number, name: contact_name)
    else
      @contact.update!(phone_number: phone_number)
    end
  end

  def contact_email
    permitted_params[:contact][:email].downcase
  end

  def contact_phone
    phone_number = permitted_params[:contact][:phone_number]
    return nil if phone_number.nil? || phone_number.blank?

    telephone = TelephoneNumber.parse(phone_number)
    telephone = TelephoneNumber.parse(phone_number, :vn) if !telephone.valid?

    telephone.e164_number
  end

  def contact_name
    params[:contact][:name] || contact_email.split('@')[0]
  end

  def browser_params
    {
      browser_name: browser.name,
      browser_version: browser.full_version,
      device_name: browser.device.name,
      platform_name: browser.platform.name,
      platform_version: browser.platform.version
    }
  end

  def timestamp_params
    { timestamp: permitted_params[:message][:timestamp] }
  end

  def permitted_params
    params.permit(:website_token)
  end

  def message_params
    {
      account_id: conversation.account_id,
      sender: @contact,
      content: permitted_params[:message][:content],
      inbox_id: conversation.inbox_id,
      echo_id: permitted_params[:message][:echo_id],
      message_type: :incoming
    }
  end
end
