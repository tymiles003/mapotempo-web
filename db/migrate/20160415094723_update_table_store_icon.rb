require 'font_awesome'

class UpdateTableStoreIcon < ActiveRecord::Migration
  def up
    Store.where.not(icon: nil).each{ |s|
      if !FontAwesome::icons_table.include?(s.icon)
        s.update!(icon: nil)
      end
    }
  end
end
