class CreateZalos < ActiveRecord::Migration[6.1]
  def change
    create_table :zalos, &:timestamps
  end
end
