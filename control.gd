extends Control

#var _plugin_name = "BattteryPlugin"
#var _android_plugin

func _ready():
	Globals.updated_data.connect(refresh_UI)
	$UIRefresh.timeout.connect(refresh_UI)
	refresh_data()
	#print(Engine.has_singleton(_plugin_name))
	#if Engine.has_singleton(_plugin_name):
		#_android_plugin = Engine.get_singleton(_plugin_name)
		#_android_plugin.requestHomeRole()
	#else:
		#printerr("Couldn't find plugin " + _plugin_name)
	#if _android_plugin != null:
		#refresh_battery()
		#$BatteryRefresh.timeout.connect(refresh_battery)



# Parse a JSON string into an array of LineEntry objects.
func parse_json(json_str: String) -> Array:
	var json = JSON.new()
	var json_result = json.parse(json_str)
	if json_result.error != OK:
		push_error("Failed to parse JSON: %s" % json_result)
		return []

	var data = json_result.data as Array
	var entries: Array = []

	for line_data in data:
		entries.append(Globals.LineEntry.new(line_data))

	return entries

func request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("Request completed")
	var json_data = JSON.parse_string(body.get_string_from_utf8())

	var timetable: Array[Globals.TimetableEntry] = []
	var line_entry: Globals.LineEntry
	# Debug output: print the parsed data
	for entry in json_data:
		print("Line ID: ", entry.lineID)
		print("Location ID: ", entry.locationID)
		print("Day: ", entry.day)
		print("Timetable:")
		line_entry = Globals.LineEntry.new(entry)
		for tt in entry.timetable:
			timetable.append(Globals.TimetableEntry.new(tt))

	Globals.MainlineEntry = line_entry
	Globals.updated_data.emit()
	#print("Next three datetimes: ", Globals.get_next_three_datetimes(timetable))
func refresh_UI():
	var next_three = Globals.get_next_three_datetimes(Globals.MainlineEntry.timetable)
	for i in range(next_three.size()):
		print("Minutes to first: ", calculate_time(Time.get_datetime_dict_from_system(), next_three[i]))
		get_node(str(i+1)).text = "%d minut, %s:%s" % [calculate_time(Time.get_datetime_dict_from_system(), next_three[i]), handle_time_number(next_three[i].hour), handle_time_number(next_three[i].minute)]
		get_node("time").text = get_current_time()

#func refresh_battery():
	#if _android_plugin != null:
		#var percent = _android_plugin.getBatteryPercentage()
		#$bateria.text = str(int(percent)) + "%"
		#
		#match _android_plugin.getBatteryStatus():
			#"discharging":
				#change_color(Color.CRIMSON)
				#change_percent(Color.CRIMSON)
				#$ladowanie.text = "Rozładowuje"
			#"charging":
				#change_color(Color.GREEN)
				#change_percent(Color.GREEN)
				#$ladowanie.text = "Ładuje..."
			#"full":
				#change_color(Color.CHARTREUSE)
				#change_percent(Color.CHARTREUSE)
				#$ladowanie.text = "Pełny"
			#"not_charging":
				#change_color(Color.ORANGE)
				#change_percent(Color.ORANGE)
				#$ladowanie.text = "Nie ładuje"
			#"unknown":
				#change_color(Color.RED)
				#change_percent(Color.RED)
				#$ladowanie.text = "NIEZNANY"
				
func change_color(color: Color):
	$ladowanie.theme.set_color("default_color", "RichTextLabel", color)
func change_percent(color: Color):
	$bateria.theme.set_color("default_color", "RichTextLabel", color)
	

func handle_time_number(number: int) -> String:
	var time = str(number)
	if time.length() == 1:
		time = "0" + time
	return time

func refresh_data():
	print("Making request")
	var todays_time = Time.get_date_dict_from_system(false)
	print("todays time", todays_time)
	var request_url = "https://live.mpk.czest.pl/api/locations/87933cc4-3afd-4138-9c7f-095bbf6ddf30/timetables/%d/%d/%d" % [todays_time.year, todays_time.month, todays_time.day]
	$HTTPRequest.request(request_url)

func get_current_time():
	var time = Time.get_datetime_dict_from_system()
	return handle_time_number(time.hour) + ":" + handle_time_number(time.minute)

func calculate_time(first_time: Dictionary, second_time: Dictionary) -> int:
	var first_time_unix = Time.get_unix_time_from_datetime_dict(first_time)
	var second_time_unix = Time.get_unix_time_from_datetime_dict(second_time)

	return (second_time_unix - first_time_unix) / 60


	return 1
