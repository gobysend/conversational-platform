# == Schema Information
#
# Table name: channel_zalo
#
#  id             :bigint           not null, primary key
#  access_token   :string           not null
#  expires_at     :datetime         not null
#  is_synced      :boolean          default(FALSE), not null
#  oa_avatar      :string
#  oa_cover       :string
#  oa_description :string
#  oa_name        :string           not null
#  refresh_token  :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :integer          not null
#  oa_id          :string           not null
#
# Indexes
#
#  index_channel_zalo_on_oa_id                 (oa_id)
#  index_channel_zalo_on_oa_id_and_account_id  (oa_id,account_id) UNIQUE
#
class Channel::Zalo < ApplicationRecord
  self.table_name = 'channel_zalo'

  validates :oa_id, uniqueness: { scope: :account_id }
  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  after_create_commit :sync_conversation_history

  def name
    'Zalo OA'
  end

  def expired?
    expires_at.before?(DateTime.now)
  end

  def has_24_hour_messaging_window?
    false
  end

  private

  def sync_conversation_history
    Inboxes::SyncConversationHistoryJob.perform_later(id, self.class.name) unless is_synced == false
  end
end
