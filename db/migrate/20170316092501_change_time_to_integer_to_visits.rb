class ChangeTimeToIntegerToVisits < ActiveRecord::Migration
  def up
    previous_times = {}
    Visit.all.order(:id).each do |visit|
      previous_times[visit.id] = {
          open1: visit.open1,
          close1: visit.close1,
          take_over: visit.take_over,
          open2: visit.open2,
          close2: visit.close2
      }
    end

    remove_column :visits, :open1
    remove_column :visits, :close1
    remove_column :visits, :take_over
    remove_column :visits, :open2
    remove_column :visits, :close2
    add_column :visits, :open1, :integer
    add_column :visits, :close1, :integer
    add_column :visits, :take_over, :integer
    add_column :visits, :open2, :integer
    add_column :visits, :close2, :integer

    Visit.reset_column_information
    Visit.transaction do
      previous_times.each do |visit_id, times|
        visit = Visit.find(visit_id)
        visit.open1 = times[:open1].seconds_since_midnight.to_i if times[:open1]
        visit.close1 = times[:close1].seconds_since_midnight.to_i if times[:close1]
        visit.take_over = times[:take_over].seconds_since_midnight.to_i if times[:take_over]
        visit.open2 = times[:open2].seconds_since_midnight.to_i if times[:open2]
        visit.close2 = times[:close2].seconds_since_midnight.to_i if times[:close2]
        visit.save!
      end
    end
  end

  def down
    previous_times = {}
    Visit.all.order(:id).each do |visit|
      previous_times[visit.id] = {
          open1: visit.open1,
          close1: visit.close1,
          take_over: visit.take_over,
          open2: visit.open2,
          close2: visit.close2
      }
    end

    remove_column :visits, :open1
    remove_column :visits, :close1
    remove_column :visits, :take_over
    remove_column :visits, :open2
    remove_column :visits, :close2
    add_column :visits, :open1, :time
    add_column :visits, :close1, :time
    add_column :visits, :take_over, :time
    add_column :visits, :open2, :time
    add_column :visits, :close2, :time

    Visit.reset_column_information
    Visit.transaction do
      previous_times.each do |visit_id, times|
        visit = Visit.find(visit_id)
        visit.open1 = Time.at(times[:open1]).utc.strftime('%H:%M:%S') if times[:open1]
        visit.close1 = Time.at(times[:close1]).utc.strftime('%H:%M:%S') if times[:close1]
        visit.take_over = Time.at(times[:take_over]).utc.strftime('%H:%M:%S') if times[:take_over]
        visit.open2 = Time.at(times[:open2]).utc.strftime('%H:%M:%S') if times[:open2]
        visit.close2 = Time.at(times[:close2]).utc.strftime('%H:%M:%S') if times[:close2]
        visit.save!
      end
    end
  end
end
