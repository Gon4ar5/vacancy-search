class EnablePgvectorAndCreateJobChunks < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector"

    create_table :job_chunks do |t|
      t.references :job, null: false, foreign_key: true
      t.integer :chunk_index, null: false
      t.text :content, null: false
      t.string :content_digest, null: false
      t.timestamps
    end

    add_column :job_chunks, :embedding, :vector, limit: 1536

    add_index :job_chunks, [ :job_id, :chunk_index ], unique: true
  end
end
