require "erb"
include ERB::Util

module IcalendarUrlHelper
  def api_planning_calendar_path user, planning
    "/api/0.1/plannings/%s.ics" % [
      planning.ref ? url_encode("ref:#{planning.ref}") : planning.id
    ]
  end
  def api_route_calendar_path user, route
    "/api/0.1/plannings/%s/routes/%s.ics" % [
      route.planning.ref ? url_encode("ref:#{route.planning.ref}") : route.planning.id,
      route.ref ? url_encode("ref:#{route.ref}") : route.id
    ]
  end
end
