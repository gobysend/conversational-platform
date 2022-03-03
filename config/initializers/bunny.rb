# config/initializers/bunny.rb

class BunnyConnectionManager
  include Singleton

  attr_accessor :active_connection, :active_channel

  def initialize
    establish_connection
    subscribe_sync_to_chat
  end

  def connection
    return active_connection if connected?

    establish_connection
    active_connection
  end

  def channel
    return active_channel if connected? && active_channel&.open?

    establish_connection
    active_channel
  end

  def connected?
    active_connection&.connected?
  end

  private

  def establish_connection
    user = ENV.fetch('RABBITMQ_USER', 'guest')
    password = ENV.fetch('RABBITMQ_PASSWORD', 'guest')
    host = ENV.fetch('RABBITMQ_HOST', 'localhost')
    port = ENV.fetch('RABBITMQ_PORT', 5672)

    @active_connection = Bunny.new(
      addresses: "#{host}:#{port}",
      username: user,
      password: password,
      vhost: ENV.fetch('RABBITMQ_VHOST', '/'),
      logger: Rails.logger
    )
    active_connection.start
    @active_channel = active_connection.create_channel

    @active_connection
  end

  def subscribe_sync_to_chat
    ch = channel
    sync_queue = ch.queue(ENV.fetch('RABBITMQ_SYNC_TO_CHAT_QUEUE', 'sync-to-chat'), durable: true, auto_delete: false)
    sync_queue.subscribe(manual_ack: true, block: false) do |delivery_info, metadata, payload|
      Rails.logger.info "Received message: #{payload}"

      # Process the message
      Workers::SyncToChatJob.instance.work(payload)

      # Delete the message
      ch.acknowledge(delivery_info.delivery_tag, false)
    end
  end
end

# Initialize to subscribe to queue
BunnyConnectionManager.instance

