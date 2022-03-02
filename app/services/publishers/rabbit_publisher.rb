class Publishers::RabbitPublisher
  include Singleton

  DEFAULT_OPTIONS = { durable: true, auto_delete: false }.freeze

  def self.publish_control_message(queue_name:, event_type:, payload:, extras: {})
    channel = BunnyConnectionManager.instance.channel
    exchange = Bunny::Exchange.new(channel, :direct, ENV.fetch('RABBITMQ_MESSAGE_EXCHANGE', 'goby.messaging'), DEFAULT_OPTIONS)

    routing_key = ENV.fetch('RABBITMQ_MESSAGE_ROUTING_KEY', 'message.control')
    channel.queue(queue_name, DEFAULT_OPTIONS).bind(exchange)

    payload = {
      eventType: event_type,
      data: payload
    }

    payload = payload.merge(extras) if extras.present?

    exchange.publish(payload.to_json, routing_key: routing_key)
  end
end
