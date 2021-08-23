class CreateChannelZaloTable < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_zalo do |t|
      t.integer :account_id, null: false
      t.string :oa_id, null: false
      t.string :oa_name, null: false
      t.string :oa_description, null: true
      t.string :oa_avatar, null: true
      t.string :oa_cover, null: true
      t.string :access_token, null: false
      t.datetime :expires_at, precision: 6, null: false
      t.timestamps
    end
  end
end
