require "erb"
include ERB::Util

module IcalendarUrlHelper
  def api_planning_calendar_path user, planning, query = nil
    "/api/0.1/plannings/%s.ics%s" % [
      planning.ref ? url_encode("ref:#{planning.ref}") : planning.id,
      query ? "?" + query : ""
    ]
  end
  def api_route_calendar_path user, route, query = nil
    "/api/0.1/plannings/%s/routes/%s.ics%s" % [
      route.planning.ref ? url_encode("ref:#{route.planning.ref}") : route.planning.id,
      route.ref ? url_encode("ref:#{route.ref}") : route.id,
      query ? "?" + query : ""
    ]
  end
end
