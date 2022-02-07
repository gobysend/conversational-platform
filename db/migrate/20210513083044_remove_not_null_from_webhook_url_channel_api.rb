class RemoveNotNullFromWebhookUrlChannelApi < ActiveRecord::Migration[6.0]
  def up
    change_column :channel_api, :webhook_url, :string, null: true
  end

  def down
    change_column :channel_api, :webhook_url, :string, null: true
  end
end
