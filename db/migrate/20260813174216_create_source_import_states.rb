class CreateSourceImportStates < ActiveRecord::Migration[8.0]
  def change
    create_table :source_import_states do |t|
      t.string :source, null: false
      t.datetime :initial_import_completed_at
      t.timestamps
    end

    add_index :source_import_states, :source, unique: true
  end
end
