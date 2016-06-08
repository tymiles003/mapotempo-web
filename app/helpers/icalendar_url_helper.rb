module IcalendarUrlHelper
  def api_planning_calendar_path user, planning
    "/api/0.1/plannings/%s/icalendar?api_key=%s" % [
      planning.ref ? "ref:#{planning.ref}" : planning.id,
      user.api_key
    ]
  end
  def api_route_calendar_path user, route
    "/api/0.1/plannings/%s/routes/%s/icalendar?api_key=%s" % [
      route.planning.ref ? "ref:#{route.planning.ref}" : route.planning.id,
      route.ref ? "ref:#{route.ref}" : route.id,
      user.api_key
    ]
  end
end
