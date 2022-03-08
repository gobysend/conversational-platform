class Zalo::DownloadConversationsService
  include Zalo::MessageBuilder::Attachments

  attr_accessor :channel

  OLDEST_CONVERSATION_BACK_DAYS = 30
  MAX_MESSAGES_IN_CONVERSATION = 500

  CONVERSATIONS_LIMIT = 10
  MESSAGES_LIMIT = 50

  def initialize(params = {})
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
    max_count = 100

    loop do
      Rails.logger.info "Fetching conversations for OA #{channel.oa_name} from #{@offset} to #{@offset + @count}..."

      url = "#{ENV['ZALO_OA_API_BASE_URL']}/listrecentchat?data=#{{ offset: @offset, count: @count }.to_json}"
      response = perform_get_request(url)
      break if response[:data].blank? || response[:error] != 0

      # Loop through list of conversations
      response[:data].each do |thread|
        # Find or create new contact_inbox and conversation
        ActiveRecord::Base.transaction do
          contact_inbox(thread)
          create_conversation(thread)
        end

        begin
          offset = 0
          count = 10

          # Loop to download messages of the conversation
          loop do
            url = "#{ENV['ZALO_OA_API_BASE_URL']}/conversation?data=#{{ user_id: @sender_id.to_i, offset: offset, count: count }.to_json}"
            response = perform_get_request(url)

            break if response[:data].blank? || response[:error] != 0

            # Save messages
            save_conversation_messages(response[:data])
            offset += count
            break if offset >= MAX_MESSAGES_IN_CONVERSATION
          end
        rescue StandardError => e
          Rails.logger.error(e)
        ensure
          # Set conversation status to open
          @conversation.update(status: 0)
        end
      end

      @offset += @count
      break if @offset >= max_count

      sleep(1)
    end

    # Mark channel as synced
    channel.update(is_synced: true)
  end

  private

  def perform_get_request(url)
    response = RestClient.get(url, { content_type: 'application/json', access_token: channel.access_token })
    if response.code == -32
      Rails.logger.info "API request for OA #{channel.oa_name} is exceeded the rate limit. Sleeping 1 minute before retrying again..."
      sleep(60)
    elsif response.code.negative?
      Rails.logger.info "Get error response for OA #{channel.oa_name}. Exiting conversation history download."
      return nil
    end

    JSON.parse(response, { symbolize_names: true })
  end

  def save_conversation_messages(messages = [])
    return if messages.nil? || messages.blank?

    ActiveRecord::Base.transaction do
      messages = messages.reverse

      messages.each do |message|
        params = message_params(message)
        next if params.nil? || params.blank?

        @conversation.messages.build(message_params(message))
      end

      @conversation.save
    end
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

  def create_conversation(thread)
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
    last_updated_at = Time.zone.at(thread[:time] / 1000).to_datetime

    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_last_seen_at: last_updated_at,
      agent_last_seen_at: last_updated_at,
      last_activity_at: last_updated_at,
      created_at: last_updated_at,
      updated_at: last_updated_at
    }
  end

  def message_params(message)
    return nil if message[:type] == 'nosupport'

    created_time = Time.zone.at(message[:time] / 1000).to_datetime

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message[:src].zero? ? 'outgoing' : 'incoming',
      content: format_message_content(message[:message]),
      private: false,
      sender: message[:src].zero? ? Current.user : @contact,
      content_type: nil,
      in_reply_to: nil,
      echo_id: nil,
      created_at: created_time,
      updated_at: created_time
    }
  end

  def format_message_content(message)
    return nil if message.nil?

    if message.start_with?('query:')
      last_index = message.rindex(/@/) + 1
      message = message[last_index..(message.length - 1)]
    end

    message
  end
end
