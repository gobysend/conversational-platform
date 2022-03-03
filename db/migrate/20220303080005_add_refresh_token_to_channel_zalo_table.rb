class AddRefreshTokenToChannelZaloTable < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_zalo, :refresh_token, :string, after: :access_token, null: true, default: nil
  end
end
