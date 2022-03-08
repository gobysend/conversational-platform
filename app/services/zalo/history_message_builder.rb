class Zalo::HistoryMessageBuilder
  attr_reader :messages

  def initialize(contact, inbox, conversation, messages)
    @messages = messages
    @inbox = inbox
    @contact = contact
    @conversation = conversation
  end

  def perform
    Rails.logger.info "Processing messages for contact #{@contact.name}"

    return if messages.blank?

    ActiveRecord::Base.transaction do
      messages.each do |message|
        build_message(message)
      end
    end
  rescue StandardError => e
    Rails.logger.error e
    Sentry.capture_exception(e)
    true
  end

  private

  def build_message(message)
    @message = @conversation.messages.build(message_params(message))

    unless message[:type] == 'text'
      params = attachment_params(message)
      attachment = @message.attachments.new(params.except(:remote_file_url))
      attach_file(attachment, params[:remote_file_url])
    end

    # Skip callback
    @message.skip_create_callbacks = true

    @message.save
  end

  def message_params(message)
    params = {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message[:src].zero? ? 'outgoing' : 'incoming',
      content: format_message_content(message[:message]),
      private: false,
      sender: message[:src].zero? ? Current.user : @contact,
      content_type: nil,
      in_reply_to: nil,
      echo_id: nil
    }

    if message[:type] == 'nosupport'
      params[:content] = 'Tin nhắn không còn tồn tại'
      params[:content_attributes] = { deleted: true }.to_s
    end

    params
  end

  def format_message_content(message)
    return nil if message.nil?

    if message.start_with?('query:')
      last_index = message.rindex(/@/) + 1
      message = message[last_index..(message.length - 1)]
    end

    message
  end

  def attach_file(attachment, file_url)
    return if file_url.blank?

    attachment_file = Down.download(
      file_url.sub!('https://', 'http://')
    )

    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )
  end

  def attachment_params(message)
    message_type = message[:type].downcase.to_sym
    params = { file_type: :fallback, account_id: @message.account_id }

    if [:photo, :file, :audio, :video].include? message_type
      params.merge!(file_type_params(message[:url]))
    elsif [:gif, :sticker].include? file_type
      params[:file_type] = :image
      params.merge!(file_type_params(message[:url]))
    elsif message_type == :location
      params.merge!(location_params(message))
    elsif message_type == :link
      params.merge!(link_params(link))
    end

    params
  end

  def file_type_params(link)
    {
      external_url: link,
      remote_file_url: link
    }
  end

  def location_params(message)
    location = JSON.parse(message[:location], { symbolize_names: true })
    lat = location[:latitude]
    long = location[:longitude]

    {
      external_url: "https://www.google.com/maps/place/#{lat},#{long}",
      coordinates_lat: lat,
      coordinates_long: long,
      fallback_title: 'Location'
    }
  end

  def link_params(message)
    link = message[:links].first
    return {} if link.blank?

    link[:name] = link[:title]

    {
      external_url: link[:thumb],
      fallback_title: link.to_json
    }
  end
end
