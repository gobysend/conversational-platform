class CreateZalos < ActiveRecord::Migration[6.1]
  def change
    create_table :zalos do |t|

      t.timestamps
    end
  end
end
