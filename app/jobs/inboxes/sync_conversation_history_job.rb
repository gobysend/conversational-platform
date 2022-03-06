class Inboxes::SyncConversationHistoryJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel_id, channel_class)
    case channel_class
    when 'Channel::Zalo'
      channel = Channel::Zalo.find(channel_id)

      service = Zalo::DownloadConversationsService.new
      service.channel = channel
      service.perform

    when 'Channel::FacebookPage'
      channel = Channel::FacebookPage.find(channel_id)

      service = Facebook::DownloadConversationsService.new
      service.channel = channel
      # service.perform
    end
  end
end
