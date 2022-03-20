class ChangeEnableEmailCollectToFalse < ActiveRecord::Migration[6.1]
  def change
    change_column :inboxes, :enable_email_collect, :boolean, default: false, null: true
  end
end
