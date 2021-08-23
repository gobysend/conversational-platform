# This class creates both outgoing messages from Gobysend and echo outgoing messages based on the flag `outgoing_echo`
# Assumptions
# 1. In case of an outgoing message which is echo, source_id will NOT be nil,
#    based on this we are showing "not sent from Gobysend" message in frontend
#    Hence there is no need to set user_id in message for outgoing echo messages.

class Messages::Zalo::MessageBuilder
  attr_reader :response

  def initialize(response, inbox, outgoing_echo: false)
    @response = response
    @inbox = inbox
    @outgoing_echo = outgoing_echo
    @sender_id = (@outgoing_echo ? @response.recipient_id : @response.sender_id)
    @message_type = (@outgoing_echo ? :outgoing : :incoming)
    @attachments = (@response.attachments || [])
  end

  def perform
    ActiveRecord::Base.transaction do
      build_contact
      build_message
    end
    ensure_contact_avatar
  rescue StandardError => e
    Rails.logger.error e
    Sentry.capture_exception(e)
    true
  end

  private

  def contact
    @contact ||= @inbox.contact_inboxes.find_by(source_id: @sender_id)&.contact
  end

  def build_contact
    return if contact.present?

    @contact = Contact.create!(contact_params.except(:remote_avatar_url))
    @contact_inbox = ContactInbox.create(contact: contact, inbox: @inbox, source_id: @sender_id)
  end

  def build_message
    @message = conversation.messages.create!(message_params)
    @attachments.each do |attachment|
      process_attachment(attachment)
    end
  end

  def process_attachment(attachment)
    return if attachment[:type].to_sym == :template

    attachment_obj = @message.attachments.new(attachment_params(attachment).except(:remote_file_url))
    attachment_obj.save!
    attach_file(attachment_obj, attachment_params(attachment)[:remote_file_url]) if attachment_params(attachment)[:remote_file_url]
  end

  def attach_file(attachment, file_url)
    attachment_file = Down.download(
      file_url
    )
    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )
  end

  def ensure_contact_avatar
    return if contact_params[:remote_avatar_url].blank?
    return if @contact.avatar.attached?

    ContactAvatarJob.perform_later(@contact, contact_params[:remote_avatar_url])
  end

  def conversation
    @conversation ||= Conversation.find_by(conversation_params) || build_conversation
  end

  def build_conversation
    @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: @sender_id)
    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id
                         ))
  end

  def attachment_params(attachment)
    file_type = attachment[:type].to_sym
    params = { file_type: file_type, account_id: @message.account_id }

    if [:image, :file, :audio, :video].include? file_type
      params.merge!(file_type_params(attachment))
    elsif [:gif, :sticker].include? file_type
      params[:file_type] = 'image'
      params.merge!(file_type_params(attachment))
    elsif file_type == :location
      params.merge!(location_params(attachment))
    elsif file_type == :link
      params.merge!(link_params(attachment))
    end

    params
  end

  def file_type_params(attachment)
    {
      external_url: attachment[:payload][:url],
      remote_file_url: attachment[:payload][:url]
    }
  end

  def location_params(attachment)
    lat = attachment[:payload][:coordinates][:lat]
    long = attachment[:payload][:coordinates][:long]
    {
      external_url: attachment[:url],
      coordinates_lat: lat,
      coordinates_long: long,
      fallback_title: attachment[:title]
    }
  end

  def link_params(attachment)
    {
      external_url: attachment[:payload][:url],
      thumbnail: attachment[:payload][:thumbnail],
      description: attachment[:payload][:description]
    }
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id
    }
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: @message_type,
      content: response.content,
      source_id: @sender_id,
      sender: @outgoing_echo ? nil : contact
    }
  end

  def contact_params
    result = {}
    begin
      if @inbox.zalo?
        response = RestClient::Request.execute(
          method: :get,
          url: "#{ENV['ZALO_OA_API_BASE_URL']}/getprofile?data={\"user_id\":\"#{@sender_id}\"}",
          headers: {
            content_type: 'application/json',
            access_token: @inbox.channel.access_token
          }
        )

        response = JSON.parse(response.body, { symbolize_names: true })

        result = response[:data] || {}
      end
    rescue RestClient::ExceptionWithResponse => e
      result = {}
      Sentry.capture_exception(e)
    end

    {
      name: result[:display_name] || 'Goby Bot',
      account_id: @inbox.account_id,
      remote_avatar_url: result[:avatars]['240']
    }
  end
end
