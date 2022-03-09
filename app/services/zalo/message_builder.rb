class Zalo::MessageBuilder
  module Attachments
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
end
