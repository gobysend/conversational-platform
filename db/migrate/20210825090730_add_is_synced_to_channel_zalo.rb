class AddIsSyncedToChannelZalo < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_zalo, :is_synced, :boolean, null: false, default: false
  end
end
