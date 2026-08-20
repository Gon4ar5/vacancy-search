class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs do |t|
      t.string :title, null: false
      t.string :company_name
      t.string :source, null: false
      t.string :source_url, null: false
      t.text :description
      t.datetime :published_at
      t.string :external_id

      t.timestamps
    end

    add_index :jobs, [ :source, :source_url ], unique: true
  end
end
