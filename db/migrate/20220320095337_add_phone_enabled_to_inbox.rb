class AddPhoneEnabledToInbox < ActiveRecord::Migration[6.1]
  def change
    add_column :inboxes, :enable_phone_collect, :boolean, after: :enable_email_collect, null: true, default: true
  end
end
