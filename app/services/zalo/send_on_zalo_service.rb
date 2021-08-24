class Zalo::SendOnZaloService < Base::SendOnChannelService
  KEY_PREFIX = 'ZALO_SENT'.freeze

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
    return if delivery_params.blank?

    url = "#{ENV['ZALO_OA_API_BASE_URL']}/message"
    response = RestClient.post(url, delivery_params.to_json, { content_type: 'application/json', access_token: channel.access_token })
    response = JSON.parse(response, { symbolize_names: true })
    message_id = response[:data][:message_id] || nil

    # Cache message_id
    if message_id.present?
      cache_key = "#{KEY_PREFIX}_#{message_id}"
      $alfred.set(cache_key, 1, { ex: 1.minute })
    end
  rescue StandardError => e
    Rails.logger.error e
  end

  def zalo_message_params
    if message.attachments.blank?
      text_message_params
    else
      with_attachment_message_params
    end
  end

  def text_message_params
    return nil if message.content.blank?

    {
      recipient: { user_id: contact.get_source_id(inbox.id) },
      message: { text: message.content }
    }
  end

  def with_attachment_message_params
    attachment = message.attachments.first

    # Zalo doesn't allow to send file over 5MB, in that case we will send user a direct link
    if attachment.file_size > 5_000_000
      return {
        recipient: { user_id: contact.get_source_id(inbox.id) },
        message: { text: "#{message.content}\n#{attachment.file_url}" }
      }
    end

    # Upload attachment to Zalo
    upload_token = upload_attachment attachment

    # Failed to upload or file is not supported, we will send text only message
    return text_message_params if upload_token.nil?

    if attachment.content_type == 'image/jpeg' || attachment.content_type == 'image/png' || attachment.content_type == 'image/gif'
      {
        recipient: { user_id: contact.get_source_id(inbox.id) },
        message: {
          text: message.content || '',
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
        recipient: { user_id: contact.get_source_id(inbox.id) },
        message: {
          text: message.content || '',
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
    return nil if attachment.file_size > 5_000_000

    file_url = attachment.file_url

    # If file is an image but larger than 1MB, we will send medium size image
    if attachment_type(attachment) == 'image'
      file_url = attachment.medium_size_url if attachment.file_size > 1_000_000
      upload_url = "#{ENV['ZALO_OA_API_BASE_URL']}/upload/image" if attachment.content_type == 'image/jpeg' || attachment.content_type == 'image/png'
      upload_url = "#{ENV['ZALO_OA_API_BASE_URL']}/upload/gif" if attachment.content_type == 'image/gif'
    end

    # Download file to local
    tmp_file = "#{Dir.tmpdir}/attachment_#{message.id}_#{Time.now.to_i}#{File.extname(URI.parse(file_url).path)}"
    File.open(tmp_file, 'wb') do |file|
      file.write(attachment.file.download)
    end

    # Upload file content to Zalo
    request = RestClient::Request.new(
      method: :post,
      url: upload_url,
      payload: {
        multipart: true,
        file: File.new(tmp_file, 'rb')
      },
      headers: {
        access_token: channel.access_token
      }
    )
    response = request.execute
    response = JSON.parse(response, { symbolize_names: true })

    # Delete temp file
    File.delete(tmp_file) if File.exist?(tmp_file)

    return nil if response.nil? || response[:data].nil? || response[:message] != 'Success'
    return response[:data][:token] if response[:data][:token].present?

    response[:data][:attachment_id]
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

end
