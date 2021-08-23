class AddIndexesToChannelZalo < ActiveRecord::Migration[6.1]
  def change
    add_index :channel_zalo, :oa_id
    add_index :channel_zalo, [:oa_id, :account_id], unique: true
  end
end
