class SyncConversationHistoryJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel_id, channel_class)
    case channel_class
    when 'Channel::Zalo'
      channel = Channel::Zalo.find(channel_id)
      Zalo::DownloadConversationsService.new(channel: channel).perform
    end
  end
end
