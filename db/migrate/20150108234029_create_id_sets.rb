class CreateIdSets < ActiveRecord::Migration
  def change
  	create_table :id_sets do |t|
      t.integer :pod_id
      t.integer :git_id
      t.string :repo
    end
  end
end
