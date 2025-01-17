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
    @contact_inbox = ContactInbox.create(contact: @contact, inbox: @inbox, source_id: @sender_id)
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
      file_url.sub!('https://', 'http://')
    )

    attachment.file.attach(
      key: "pages/attachments/account_#{@contact.account_id}/inbox_#{@inbox.id}/#{Time.now.to_i}_#{attachment_file.original_filename}",
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
      params[:file_type] = :image
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
    lat = attachment[:payload][:coordinates][:latitude]
    long = attachment[:payload][:coordinates][:longitude]
    {
      external_url: "https://www.google.com/maps/place/#{lat},#{long}",
      coordinates_lat: lat,
      coordinates_long: long,
      fallback_title: @response.content || "#{@contact.name}'s location"
    }
  end

  def link_params(attachment)
    fallback_title = JSON.parse(attachment[:payload][:description])
    fallback_title['name'] = @response.content
    {
      external_url: attachment[:payload][:thumbnail],
      fallback_title: fallback_title.to_json
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
    result = zalo_profile(@sender_id, @inbox.channel.access_token)

    {
      name: result[:display_name] || 'Unknown',
      account_id: @inbox.account_id,
      remote_avatar_url: (result[:avatars].present? ? result[:avatars][:'240'] : nil) || nil,
      identifier: result[:user_id],
      custom_attributes: {
        gender: (result[:user_gender].present? && result[:user_gender].zero?) ? 'Nữ' : 'Nam',
        birth_date: result[:birth_date].present? ? Time.zone.at(result[:birth_date].to_i).strftime('%Y-%m-%d') : nil
      }
    }
  end

  def zalo_profile(user_id, access_token)
    begin
      response = RestClient::Request.execute(
        method: :get,
        url: "#{ENV['ZALO_OA_API_BASE_URL']}/getprofile?data={\"user_id\":\"#{user_id}\"}",
        headers: { content_type: 'application/json', access_token: access_token }
      )

      response = JSON.parse(response.body, { symbolize_names: true })

      result = response[:data] || {}
    rescue RestClient::ExceptionWithResponse => e
      result = {}
      Rails.logger.error(e)
      puts "Error getting Zalo profile #{e.message}"
    end

    result
  end
end
