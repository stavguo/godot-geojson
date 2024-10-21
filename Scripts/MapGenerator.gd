extends ColorRect

var item_data = {}
var coord_scale = 100000000
var min_lat = INF
var max_lat = -INF
var min_long = INF
var max_long = -INF

var data_file_path: String = "res://Data/sangenjaya.geojson"

func _ready():
	item_data = load_json_file(data_file_path)
	if item_data:
		extract_min_max_coords(item_data)
		get_parent().set_size(project(min_lat, max_long) - project(max_lat, min_long))

func _draw():
	print(get_parent_area_size())
	if item_data:
		for feature in item_data.features:
			# Draw roads
			if feature.geometry.type == "LineString":
				var road = Line2D.new()
				for coord in feature.geometry.coordinates:
					# TODO: Normalizng pixel coord like this depends on hemisphere.
					var p = project(coord[1], coord[0]) - project(max_lat, min_long)
					road.add_point(p)
				draw_polyline(road.get_points(), Color(0,1,0), 1.0, false)
			# Draw buildings
			if feature.geometry.type == "Polygon":
				for building in feature.geometry.coordinates:
					var points = PackedVector2Array()
					for coord in building:
						# TODO: Normalizng pixel coord like this depends on hemisphere.
						var p = project(coord[1], coord[0]) - project(max_lat, min_long)
						points.append(p)
					draw_polygon(points, PackedColorArray([Color(255,0,255)]))

func extract_min_max_coords(geojson_data):
	for feature in geojson_data.features:
		if feature.geometry.type == "LineString":
			for coord in feature.geometry.coordinates:
				var lat = coord[1]
				var lon = coord[0]
				if lat < min_lat:
					min_lat = lat
				if lat > max_lat:
					max_lat = lat
				if lon < min_long:
					min_long = lon
				if lon > max_long:
					max_long = lon
	print("Min Latitude: ", min_lat)
	print("Max Latitude: ", max_lat)
	print("Min Longitude: ", min_long)
	print("Max Longitude: ", max_long)

func load_json_file(file_path: String):
	if FileAccess.file_exists(file_path):
		var data_file = FileAccess.open(file_path, FileAccess.READ)
		var parsed_result = JSON.parse_string(data_file.get_as_text())
		if parsed_result is Dictionary:
			print("Loaded item_data dictionary.")
			return parsed_result
		else:
			print("Error reading file.")
	else:
		print("File does not exist.")
	return null

# https://medium.com/@suverov.dmitriy/how-to-convert-latitude-and-longitude-coordinates-into-pixel-offsets-8461093cb9f5
func latLonToOffsets(latitude, longitude, mapWidth, mapHeight):
	var FE = 180 # false easting
	var radius = mapWidth / (2 * PI)

	var latRad = deg_to_rad(latitude)
	var lonRad = deg_to_rad(longitude + FE)

	var x = lonRad * radius

	var yFromEquator = radius * log(tan(PI / 4 + latRad / 2))
	var y = mapHeight / 2 - yFromEquator
	return Vector2(x, y)

#https://developers.google.com/maps/documentation/javascript/examples/map-coordinates
func get_pixel_coord(lat: float, lng: float) -> Vector2:
	return Vector2(
		project(lat, lng).x * coord_scale,
		project(lat, lng).y * coord_scale
	)

#https://developers.google.com/maps/documentation/javascript/examples/map-coordinates
func project(lat: float, lng: float) -> Vector2:
	var siny = sin((lat * PI) / 180)

	# Truncating to 0.9999 effectively limits latitude to 89.189. This is
	# about a third of a tile past the edge of the world tile.
	siny = min(max(siny, -0.9999), 0.9999)

	return Vector2(
		coord_scale * (0.5 + lng / 360),
		coord_scale * (0.5 - log((1 + siny) / (1 - siny)) / (4 * PI))
	)

func log_min_max_coords() -> void:
	print("min_lat = %s" % min_lat)
	print("min_long = %s" % min_long)
	print("max_lat = %s" % max_lat)
	print("max_long = %s" % max_long)
