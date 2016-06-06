module PlanningIcalendar
  extend ActiveSupport::Concern

  require 'icalendar/tzinfo'

  def planning_date route
    route.planning.date ? route.planning.date.beginning_of_day.to_time : Time.now.beginning_of_day
  end

  def p_time route, time
    planning_date(route) + (time - Time.new(2000, 1, 1, 0, 0, 0, '+00:00'))
  end

  def stop_ics route, stop, event_start, event_stop
    event = Icalendar::Event.new
    event.uid = [stop.id, stop.visit_id].join("-")
    event.dtstart = event_start
    event.dtend = event_stop
    event.summary = stop.name
    event.location = [stop.street, stop.postalcode, stop.city, stop.country, stop.detail].reject(&:blank?).join(", ")
    event.categories = !route.ref.blank? ? route.ref : route.vehicle_usage.vehicle.name
    event.description = stop.comment
    event.created = stop.created_at
    event.last_modified = stop.updated_at
    event.organizer = Icalendar::Values::CalAddress.new("mailto:#{@current_user.email}", cn: @current_user.customer.name)
    if stop.duration
      hours = stop.duration.to_i / 3600
      minutes = (stop.duration.to_i - hours * 3600) / 60
      seconds = (stop.duration.to_i - hours * 3600 - minutes * 60)
      event.duration = Icalendar::Values::Duration.new("#{hours}H#{minutes}M#{seconds}S").value_ical
    end
    event.geo = [stop.lat, stop.lng]
    return event
  end

  def add_route_to_calendar calendar, route
    route.stops.select(&:active?).select(&:position?).sort_by(&:index).each do |stop|
      next if !stop.time
      event_start = p_time(route, stop.open || stop.time)
      event_stop = p_time(route, stop.close || stop.time)
      calendar.add_timezone TZInfo::Timezone.get(Time.zone.tzinfo.name).ical_timezone(event_start)
      calendar.add_event stop_ics(route, stop, event_start, event_stop)
    end
  end

  def planning_calendar planning
    calendar = Icalendar::Calendar.new
    planning.routes.select(&:vehicle_usage).each do |route|
      add_route_to_calendar calendar, route
    end
    return calendar
  end

  def route_calendar route
    calendar = Icalendar::Calendar.new
    add_route_to_calendar calendar, route
    return calendar
  end

end
