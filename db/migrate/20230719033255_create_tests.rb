class CreateTests < ActiveRecord::Migration[6.1]
  def change
    create_table :tests do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.integer :score
      t.integer :status
      t.references :subject, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
