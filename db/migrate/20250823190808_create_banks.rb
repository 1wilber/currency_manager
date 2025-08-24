class CreateBanks < ActiveRecord::Migration[8.0]
  def change
    create_table :banks do |t|
      t.string :name

      t.timestamps
    end
    add_index :banks, :name
  end
end
