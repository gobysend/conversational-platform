module Channelable
  extend ActiveSupport::Concern
  included do
    belongs_to :account
    has_one :inbox, as: :channel, dependent: :destroy_async
  end

  def has_24_hour_messaging_window?
    false
  end
end
