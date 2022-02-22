class Zalo::DownloadConversationsService
  attr_accessor :channel

  def initialize(params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def perform
    @offset = 0
    @count = 10

    # Get inbox for current channel
    inbox

    # Load only 100 recent conversations
    max_count = 1000

    loop do
      Rails.logger.info "Fetching conversations for OA #{channel.oa_name} from #{@offset} to #{@offset + @count}..."
      url = "#{ENV['ZALO_OA_API_BASE_URL']}/listrecentchat?data=#{{ offset: @offset, count: @count }.to_json}"
      response = RestClient.get(url, { content_type: 'application/json', access_token: channel.access_token })
      if response.code == -32
        Rails.logger.info "API request for OA #{channel.oa_name} is exceeded the rate limit. Sleeping 1 minute before retrying again...zzzzz"
        sleep(1.minute)
      elsif response.code.negative?
        Rails.logger.info "Get error response for OA #{channel.oa_name}. Exiting conversation history download."
        break
      end

      response = JSON.parse(response, { symbolize_names: true })
      break if response[:data].blank? || response[:error] != 0

      response[:data].each do |thread|
        download_conversation_messages(thread)
      end

      @offset += @count
      break if @offset >= max_count

      sleep(1)
    end

    # Mark channel as synced
    channel.update(is_synced: true)
  end

  private

  def download_conversation_messages(thread)
    offset = 0, count = 10, max_messages = 200

    ActiveRecord::Base.transaction do
      contact_inbox(thread)
      conversation(thread)
    end

    ensure_contact_avatar(thread)
    messages = []

    loop do
      to_offset = offset + count

      if thread[:src].zero?
        Rails.logger.info "Fetching messages for conversation with #{thread[:to_display_name]} from #{offset} to #{to_offset}"
      else
        Rails.logger.info "Fetching messages for conversation with #{thread[:from_display_name]} from #{offset} to #{to_offset}"
      end

      url = "#{ENV['ZALO_OA_API_BASE_URL']}/conversation?data=#{{ user_id: @sender_id.to_i, offset: offset, count: count }.to_json}"
      response = RestClient.get(url, { content_type: 'application/json', access_token: channel.access_token })
      if response.code == -32
        Rails.logger.info "API request for OA #{channel.oa_name} is exceeded the rate limit. Sleeping 1 minute before retrying again..."
        sleep(1.minute)
      elsif response.code.negative?
        Rails.logger.info "Get error response for OA #{channel.oa_name}. Exiting conversation history download."
        break
      end

      offset += count

      response = JSON.parse(response, { symbolize_names: true })

      break if response[:data].blank? || response[:error] != 0

      # Buffer messages
      response[:data].each do |message|
        messages.unshift(message)
      end

      break if offset >= max_messages
    end

    # Save messages
    mb = ::Zalo::HistoryMessageBuilder.new(@contact, @inbox, @conversation, messages)
    mb.perform

    return unless messages.any?

    # Set last activity for conversation
    last_activity_at = Time.zone.at(messages.last[:time]).to_datetime
    @conversation.update(last_activity_at: last_activity_at, status: 0)
    @contact.update(last_activity_at: last_activity_at)
  end

  def inbox
    @inbox = channel.inbox
  end

  def contact_inbox(thread)
    @sender_id = thread[:src] == 1 ? thread[:from_id] : thread[:to_id]
    @contact = Contact.find_by(identifier: @sender_id)
    @contact ||= Contact.create!(contact_params(thread).except(:remote_avatar_url))

    @contact_inbox = @inbox.contact_inboxes.find_by(source_id: @sender_id)
    @contact_inbox ||= ContactInbox.create(contact: @contact, inbox: @inbox, source_id: @sender_id)
  end

  def ensure_contact_avatar(thread)
    params = contact_params(thread)
    return if params[:remote_avatar_url].blank?
    return if @contact.avatar.attached?

    ContactAvatarJob.perform_later(@contact, params[:remote_avatar_url])
  end

  def contact_params(thread)
    if thread[:src].zero?
      # Outgoing
      {
        name: thread[:to_display_name] || 'Unknown',
        account_id: @inbox.account_id,
        remote_avatar_url: thread[:to_avatar],
        identifier: thread[:to_id]
      }
    else
      # Incoming
      {
        name: thread[:from_display_name] || 'Unknown',
        account_id: @inbox.account_id,
        remote_avatar_url: thread[:from_avatar],
        identifier: thread[:from_id]
      }
    end
  end

  def conversation(thread)
    @conversation = Conversation.find_by(
      {
        account_id: @inbox.account_id,
        inbox_id: @inbox.id,
        contact_id: @contact.id
      }
    ) || build_conversation(thread)
  end

  def build_conversation(thread)
    Conversation.create!(conversation_params(thread).merge(contact_inbox_id: @contact_inbox.id, skip_notify_creation: true, status: 2))
  end

  def conversation_params(thread)
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_last_seen_at: Time.zone.at(thread[:time]).to_datetime,
      agent_last_seen_at: Time.zone.at(thread[:time]).to_datetime
    }
  end
end
