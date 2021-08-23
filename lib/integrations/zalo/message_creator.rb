# frozen_string_literal: true

class Integrations::Zalo::MessageCreator
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def perform
    # begin
    if agent_message_via_echo?
      create_agent_message
    else
      create_contact_message
    end
    # rescue => e
    # Sentry.capture_exception(e)
    # end
  end

  private

  def agent_message_via_echo?
    response.sent_by_agent_from_zalo?
    # This means that it is an agent message from OA page, but not sent from Gobysend
    # Because user can send from Zalo OA page directly on mobile/web chat, so this case should be handled as agent message
  end

  def create_agent_message
    Channel::Zalo.where(oa_id: response.sender_id).each do |oa|
      mb = Messages::Zalo::MessageBuilder.new(response, oa.inbox, outgoing_echo: true)
      mb.perform
    end
  end

  def create_contact_message
    Channel::Zalo.where(oa_id: response.recipient_id).each do |oa|
      mb = Messages::Zalo::MessageBuilder.new(response, oa.inbox)
      mb.perform
    end
  end
end
