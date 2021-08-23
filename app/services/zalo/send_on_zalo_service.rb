class Zalo::SendOnZaloService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Zalo
  end

  def perform_reply
    send_message_to_zalo zalo_message_params
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
    Rails.logger.info e
  end

  def send_message_to_zalo(delivery_params)
    url = "#{ENV['ZALO_OA_API_BASE_URL']}/message"
    RestClient.post(url, delivery_params, { content_type: 'application/json', access_token: channel.access_token })
  end

  def zalo_message_params
    if message.attachments.blank?
      text_message_params
    else
      with_attachment_message_params
    end
  end

  def text_message_params
    {
      recipient: { user_id: contact.get_source_id(inbox.id) },
      message: { text: message.content }
    }
  end

  def with_attachment_message_params
    attachment = message.attachments.first
    upload_token = upload_attachment attachment

    if attachment.content_type == 'image/jpeg' || attachment.content_type == 'image/png' || attachment.content_type == 'image/gif'
      {
        recipient: { id: contact.get_source_id(inbox.id) },
        message: {
          text: message.content?,
          attachment: {
            type: 'template',
            payload: {
              template_type: 'media',
              elements: [
                { media_type: 'image', attachment_id: upload_token }
              ]
            }
          }
        }
      }
    else
      {
        recipient: { id: contact.get_source_id(inbox.id) },
        message: {
          text: message.content?,
          attachment: {
            type: 'file',
            payload: {
              token: upload_token
            }
          }
        }
      }
    end
  end

  def upload_attachment(attachment)
    upload_url = "#{ENV['ZALO_OA_API_BASE_URL']}/upload/file"

    # Do NOT allow file size over 5MB
    return nil if attachment.size > 5_000_000

    file_url = attachment.file_url

    # If file is an image but larger than 1MB, we will send medium size image
    if attachment_type(attachment) == 'image'
      file_url = attachment.medium_size_url if attachment.size > 1_000_000
      upload_url = "#{ENV['ZALO_OA_API_BASE_URL']}/upload/image" if attachment.content_type == 'image/jpeg' || attachment.content_type == 'image/png'
      upload_url = "#{ENV['ZALO_OA_API_BASE_URL']}/upload/gif" if attachment.content_type == 'image/gif'
    end

    # Download file to local before uploading to Zalo
    file_contents = Net::HTTP.get_response(URI.parse(file_url)).body

    # Upload file content to Zalo
    request = RestClient::Request.new(
      method: :post,
      url: upload_url,
      payload: {
        multipart: true,
        file: file_contents
      }
    )
    response = request.execute

    return nil if response.nil? || response[:data].nil? || !response[:message] != 'Success'
    return response[:data][:token] unless response[:data][:token].nil?

    response[:data][:attachment_id]
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end
end
