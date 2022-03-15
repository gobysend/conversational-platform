class Facebook::DownloadConversationsService
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
    # Get inbox for current channel
    inbox
    return if @inbox.nil?

    oldest_date = Time.zone.current.beginning_of_day - OLDEST_CONVERSATION_BACK_DAYS.days

    FbGraph2.api_version = 'v13.0'
    fb = FbGraph2::Page.new(channel.page_id).authenticate(channel.page_access_token)

    threads = fb.conversations(limit: CONVERSATIONS_LIMIT, fields: 'senders,id,updated_time,message_count,unread_count,can_reply')

    loop do
      break if threads.nil? || threads.blank?

      reach_oldest = false
      index = 0

      threads.each do |thread|
        if Time.zone.at(thread.updated_time).to_datetime <= oldest_date
          reach_oldest = true
          break
        end

        # Find or create new contact_inbox and conversation
        ActiveRecord::Base.transaction do
          contact_inbox(thread)
          create_conversation(thread)
        end

        begin
          # Loop to download messages of the conversation
          messages = thread.messages(limit: MESSAGES_LIMIT, fields: 'message,to,tags,id,from,created_time')

          loop do
            offset = index * MESSAGES_LIMIT
            Rails.logger.info "Fetching messages for thread #{thread.id} from #{offset} to #{offset + MESSAGES_LIMIT}"

            break if messages.nil? || messages.blank?

            save_conversation_messages(messages)

            index += 1
            break if (offset + MESSAGES_LIMIT) >= MAX_MESSAGES_IN_CONVERSATION

            # Get the next page of the messages within the conversation
            messages = messages.next
          end
        rescue StandardError => e
          Rails.logger.error(e)
        ensure
          # Set conversation status to resolved
          @conversation.update(status: 1)
        end
      end

      # Stop getting older threads if reach the oldest
      break if reach_oldest

      threads = threads.next
    end
  end

  private

  def inbox
    @inbox = channel.inbox
  end

  def save_conversation_messages(messages = [])
    return if messages.nil? || messages.blank?

    ActiveRecord::Base.transaction do
      messages = messages.reverse

      messages.each do |message|
        @conversation.messages.build(message_params(message))
      end

      @conversation.save
    end
  end

  def contact_inbox(thread)
    sender = thread.senders.find { |sender| sender.id != channel.page_id }
    @sender_id = sender.id
    @contact = Contact.find_by(identifier: @sender_id)
    @contact ||= Contact.create!(contact_params(sender))

    @contact_inbox = @inbox.contact_inboxes.find_by(source_id: @sender_id)
    @contact_inbox ||= ContactInbox.create(contact: @contact, inbox: @inbox, source_id: @sender_id)
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
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_last_seen_at: Time.zone.at(thread.updated_time).to_datetime,
      agent_last_seen_at: Time.zone.at(thread.updated_time).to_datetime,
      last_activity_at: Time.zone.at(thread.updated_time).to_datetime,
      created_at: Time.zone.at(thread.updated_time).to_datetime,
      updated_at: Time.zone.at(thread.updated_time).to_datetime
    }
  end

  def contact_params(sender)
    {
      name: sender.name,
      account_id: @inbox.account_id,
      identifier: sender.id
    }
  end

  def message_params(message)
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message.from.id == channel.page_id ? 'outgoing' : 'incoming',
      content: message.message,
      private: false,
      sender: message.from.id == channel.page_id ? @contact : nil,
      content_type: 0,
      in_reply_to: nil,
      echo_id: nil,
      skip_create_callbacks: true,
      source_id: message.id,
      created_at: Time.zone.at(message.created_time).to_datetime,
      updated_at: Time.zone.at(message.created_time).to_datetime
    }
  end
end
