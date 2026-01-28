extends Control

# Cache nodes for performance and cleaner access
@onready var ui_refresh_timer: Timer = $UIRefresh
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var time_label: RichTextLabel = $time

func _ready() -> void:
	Globals.updated_data.connect(refresh_UI)
	ui_refresh_timer.timeout.connect(refresh_UI)
	refresh_data()

func request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		get_node("1").text = "BRAK"
		get_node("2").text = "POLACZENIA"
		get_node("3").text = "Z MPK"
		push_error("Request failed. Result: %d, Code: %d" % [result, response_code])
		return

	print("Request completed")
	
	var json_data = JSON.parse_string(body.get_string_from_utf8())
	if json_data == null:
		push_error("Failed to parse JSON response")
		return

	var line_entry: Globals.LineEntry
	
	for entry in json_data:
		line_entry = Globals.LineEntry.new(entry)

	if line_entry:
		Globals.MainlineEntry = line_entry
		Globals.updated_data.emit()

func refresh_UI() -> void:
	if not Globals.MainlineEntry:
		return

	var next_three: Array = Globals.get_next_three_datetimes(Globals.MainlineEntry.timetable)
	
	# Loop safely based on available data
	for i in range(next_three.size()):
		var target_time: Dictionary = next_three[i]
		var minutes_diff: int = calculate_minutes_diff(Time.get_datetime_dict_from_system(), target_time)
		
		print("Minutes to next: ", minutes_diff)
		
		# Check if the node exists before trying to access it
		var node_name = str(i + 1)
		if has_node(node_name):
			# %02d automatically adds the leading zero if needed (e.g., 5 becomes 05)
			get_node(node_name).text = "%d minut, %02d:%02d" % [
				minutes_diff, 
				target_time.hour, 
				target_time.minute
			]
			
	time_label.text = get_current_time_string()

func refresh_data() -> void:
	print("Making request")
	var t: Dictionary = Time.get_date_dict_from_system(false)
	# Assuming this URL structure is constant
	var request_url = "https://live.mpk.czest.pl/api/locations/87933cc4-3afd-4138-9c7f-095bbf6ddf30/timetables/%d/%d/%d" % [t.year, t.month, t.day]
	http_request.request(request_url)

func get_current_time_string() -> String:
	var t: Dictionary = Time.get_datetime_dict_from_system()
	return "%02d:%02d" % [t.hour, t.minute]

func calculate_minutes_diff(first_time: Dictionary, second_time: Dictionary) -> int:
	var first_unix: int = Time.get_unix_time_from_datetime_dict(first_time)
	var second_unix: int = Time.get_unix_time_from_datetime_dict(second_time)
	return (second_unix - first_unix) / 60
