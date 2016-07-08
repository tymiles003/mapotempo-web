class AlterCustomer2Tw < ActiveRecord::Migration
  def self.up
    Customer.all.each{ |c|
      if c.advanced_options && (c.advanced_options.include?('"open":') || c.advanced_options.include?('"close":'))
        c.advanced_options = c.advanced_options.gsub('"open":', '"open1":')
        c.advanced_options = c.advanced_options.gsub('"close":', '"close1":')
        c.save!
      end
    }
  end

  def self.down
    Customer.all.each{ |c|
      if c.advanced_options && (c.advanced_options.include?('"open1":') || c.advanced_options.include?('"close1":') || c.advanced_options.include?('"open2":') || c.advanced_options.include?('"close2":'))
        c.advanced_options = c.advanced_options.gsub('"open1":', '"open":')
        c.advanced_options = c.advanced_options.gsub('"close1":', '"close":')
        options = JSON.parse(c.advanced_options)
        options['import']['destinations']['spreadsheetColumnsDef'].delete('open2') if options['import'] && options['import']['destinations'] && options['import']['destinations']['spreadsheetColumnsDef'] && options['import']['destinations']['spreadsheetColumnsDef'].key?('open2')
        options['import']['destinations']['spreadsheetColumnsDef'].delete('close2') if options['import'] && options['import']['destinations'] && options['import']['destinations']['spreadsheetColumnsDef'] && options['import']['destinations']['spreadsheetColumnsDef'].key?('close2')
        c.update! advanced_options: options.to_json
      end
    }
  end
end
