# frozen_string_literal: true

class Integrations::Zalo::MessageParser
  def initialize(response_json)
    @response = response_json
  end

  def oa_id
    @response[:oa_id]
  end

  def app_id
    @response[:app_id]
  end

  def event_name
    @response[:event_name]
  end

  def sender_id
    @response[:sender][:id]
  end

  def recipient_id
    @response[:recipient][:id]
  end

  def user_id_by_app
    @response[:user_id_by_app]
  end

  def timestamp
    @response[:timestamp]
  end

  def content
    @response[:message][:text]
  end

  def message_id
    @response[:message][:msg_id]
  end

  def attachments
    @response[:message][:attachments]
  end

  def source
    @response[:source]
  end

  def follower_id
    @response[:follower][:id]
  end

  def sent_by_agent_from_zalo?
    event_name&.start_with?('oa_send_')
  end

  def identifier
    recipient_id if sent_by_agent_from_zalo?
    sender_id
  end
end

# Sample Response
# {
#     "app_id": "360846524940903967",
#     "sender": {
#         "id": "246845883529197922"
#     },
#     "user_id_by_app": "552177279717587730",
#     "recipient": {
#         "id": "388613280878808645"
#     },
#     "event_name": "user_send_text",
#     "message": {
#         "text": "message",
#         "msg_id": "96d3cdf3af150460909"
#     },
#     "timestamp": "154390853474"
# }
