# a Neighborhood map is a map displays:
#
# * the boundary for the neighborhood
# * the heatmap for the neighborhood
#
# usage:
# map = NeighborhoodMap.build('#neighborhood_map', neighborhood_id)
#
# See Also:
#
# http://www.patrick-wied.at/static/heatmapjs/docs.html
#
class Whathood.Map.NeighborhoodMap extends Whathood.Map

  # need to build the map because the heatmapLayer
  # needs to go into the map constructor
  @build: (css_id, neighborhood_id) ->
    throw new Error "neighborhood_id must be defined" unless neighborhood_id

    $.ajax
      url: Whathood.UrlBuilder.heatmap_points_by_n_id neighborhood_id
      success: (heatmap_points) =>

        streetLayer   = Whathood.Map.streetLayer()
        heatmapLayer  = new Whathood.Map.HeatmapLayer()
        map = new Whathood.Map.NeighborhoodMap css_id,
          center: new L.LatLng(39.962863586971,-75.126734904035)
          zoom: 14
          layers: [streetLayer,heatmapLayer]

        info = new Whathood.Map.NeighborhoodMapControl()
        info.addTo map
        info.update $("#map").data()

        heatmapLayer.buildData neighborhood_id, () ->
          url = Whathood.UrlBuilder.neighborhood_border_by_id(neighborhood_id)
          map.addNeighborhoodBorder url, (geojson) ->
            map.fitBounds(heatmapLayer)
            heatmapLayer.redraw()
            # add the neighborhood boundary
            new L.geoJson(geojson).addTo(map)
        return map

  # sugar
  addNeighborhoodBorder: (url, cb) ->
    @addGeoJson url, cb
