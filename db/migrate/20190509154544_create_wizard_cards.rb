class CreateWizardCards < ActiveRecord::Migration
  def change
    create_table :widget_cards do |t|
      t.string :title
      t.text :description
      t.string :link_text
      t.string :link_url
      t.string :label
      t.boolean :header, default: false
      t.timestamps null: false
    end
  end
end
