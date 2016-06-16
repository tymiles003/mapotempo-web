module PlanningIcalendar
  require 'icalendar/tzinfo'

  def planning_date route
    route.planning.date ? route.planning.date.beginning_of_day.to_time : Time.zone.now.beginning_of_day
  end

  def p_time route, time
    planning_date(route) + (time - Time.new(2000, 1, 1, 0, 0, 0, '+00:00'))
  end

  def stop_ics route, stop, event_start
    event = Icalendar::Event.new
    event.uid = [stop.id, stop.visit_id].join("-")
    event.dtstart = event_start
    event.summary = stop.name
    event.location = [stop.street, stop.detail, stop.postalcode, stop.city, stop.country].reject(&:blank?).join(", ")
    event.categories = route.ref || route.vehicle_usage.vehicle.name.gsub(",", "")
    event.description = [stop.phone_number, stop.comment].reject(&:blank?).join("\n")
    event.created = stop.created_at
    event.last_modified = stop.updated_at
    event.organizer = Icalendar::Values::CalAddress.new("mailto:#{@current_user.email}", cn: @current_user.customer.name)
    if stop.phone_number
      event.attendee = Icalendar::Values::CalAddress.new("tel:#{stop.phone_number}", cn: stop.phone_number)
    end
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
    route.stops.select(&:active?).select(&:position?).select(&:time?).sort_by(&:index).each do |stop|
      event_start = p_time(route, stop.time)
      calendar.add_timezone TZInfo::Timezone.get(Time.zone.tzinfo.name).ical_timezone(event_start)
      calendar.add_event stop_ics(route, stop, event_start)
    end
  end

  def plannings_calendar plannings
    calendar = Icalendar::Calendar.new
    plannings.each do |planning|
      planning.routes.select(&:vehicle_usage).each do |route|
        add_route_to_calendar calendar, route
      end
    end
    return calendar
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

  def route_calendar_email route
    if route.vehicle_usage.vehicle.contact_email
      vehicle = route.vehicle_usage.vehicle
      url = api_route_calendar_path(route, api_key: @current_user.api_key)
      name = route.ref || route.vehicle_usage.vehicle.name
      if Mapotempo::Application.config.delayed_job_use
        RouteMailer.delay.send_ics_route @current_user, I18n.locale, vehicle, route, name + '.ics', url
      else
        RouteMailer.send_ics_route(@current_user, I18n.locale, vehicle, route, name + '.ics', url).deliver_now
      end
    end
  end

end
