module PlanningIcalendar
  extend ActiveSupport::Concern

  require 'icalendar/tzinfo'

  def planning_date route
    route.planning.date ? route.planning.date.beginning_of_day.to_time : Time.now.beginning_of_day
  end

  def p_time route, time
    planning_date(route) + (time - Time.new(2000, 1, 1, 0, 0, 0, '+00:00'))
  end

  def stop_ics route, stop, event_start
    event = Icalendar::Event.new
    event.uid = [stop.id, stop.visit_id].join("-")
    event.dtstart = event_start
    event.summary = stop.name
    event.location = [stop.street, stop.postalcode, stop.city, stop.country, stop.detail].reject(&:blank?).join(", ")
    event.categories = !route.ref.blank? ? route.ref : route.vehicle_usage.vehicle.name.gsub(",", "")
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
    route.stops.select(&:active?).select(&:position?).select(&:time?).sort_by(&:index).each do |stop|
      event_start = p_time(route, stop.time)
      calendar.add_timezone TZInfo::Timezone.get(Time.zone.tzinfo.name).ical_timezone(event_start)
      calendar.add_event stop_ics(route, stop, event_start)
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

  def icalendar_route_export planning, route
    filename = export_filename planning, route.ref || route.vehicle_usage.vehicle.name
    header 'Content-Disposition', "attachment; filename=\"#{filename}.ics\""
    route_calendar(route).to_ical
  end

  def icalendar_planning_export planning
    filename = export_filename planning, planning.ref
    header 'Content-Disposition', "attachment; filename=\"#{filename}.ics\""
    planning_calendar(planning).to_ical
  end

  def icalendar_export_email planning, route
    if route.vehicle_usage.vehicle.contact_email
      vehicle = route.vehicle_usage.vehicle
      url = api_route_calendar_path @current_user, route
      name = export_filename route.planning, route.ref || route.vehicle_usage.vehicle.name
      if Mapotempo::Application.config.delayed_job_use
        RouteMailer.delay.send_ics_route @current_user, vehicle, route, name + '.ics', url
      else
        RouteMailer.send_ics_route(@current_user, vehicle, route, name + '.ics', url).deliver_now
      end
    end
  end

end
