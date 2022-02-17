class AddAllowedLogInToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :allowed_log_in, :boolean, null: false, default: true
  end
end
