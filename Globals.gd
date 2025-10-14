extends Node

signal updated_data

func apply_timezone_offset(datetime_dict: Dictionary) -> Dictionary:
	# Convert the datetime dictionary to a Unix timestamp
	var unix_time = Time.get_unix_time_from_datetime_dict(datetime_dict)

	# Apply the timezone offset (convert minutes to seconds)
	unix_time += Time.get_time_zone_from_system().bias * 60

	# Convert back to a datetime dictionary
	return Time.get_datetime_dict_from_unix_time(unix_time)
# TimetableEntry class


class TimetableEntry:
	var dateTime: Dictionary
	var runID: String
	var vehicleID: String
	var direction: String


	func _init(data: Dictionary) -> void:
		dateTime = Globals.apply_timezone_offset(Time.get_datetime_dict_from_datetime_string(data.get("dateTime", ""), false))
		runID = data.get("runID", "")
		if data.has("vehicleID") and data.get("vehicleID") != null:
			vehicleID = data.get("vehicleID")
		else:
			vehicleID = "NONE"
		direction = data.get("direction", "")


# LineEntry class
class LineEntry:
	var lineID: String
	var locationID: String
	var day: Dictionary
	var timetable: Array[TimetableEntry]

	func _init(data: Dictionary) -> void:
		lineID = data.get("lineID", "")
		locationID = data.get("locationID", "")
		day = Globals.apply_timezone_offset(Time.get_datetime_dict_from_datetime_string(data.get("day", ""), false))
		timetable = []
		var tt_array = data.get("timetable", [])
		for tt_data in tt_array:
			timetable.append(TimetableEntry.new(tt_data))
			
var MainlineEntry: LineEntry

func datetime_array_from_timetable_entry_array(timetable_array: Array[TimetableEntry]) -> Array[Dictionary]:
	var new_array: Array[Dictionary] = []
	for entry in timetable_array:
		new_array.append(entry.dateTime)
		
	return new_array
	
# Returns an array of the 3 datetime dictionaries that are in the future (closest first)
func get_next_three_datetimes(times: Array[TimetableEntry], current_datetime: Dictionary = Time.get_datetime_dict_from_system(false)) -> Array:
	var current_ts = Time.get_unix_time_from_datetime_dict(current_datetime)
	var future_times = []
	
	# Filter only the datetime dicts that are in the future.
	for dt in datetime_array_from_timetable_entry_array(times):
		var dt_ts = Time.get_unix_time_from_datetime_dict(dt)
		if dt_ts > current_ts:
			future_times.append(dt_ts)
	
	## Sort future_times by their Unix timestamp (ascending order)
	#future_times.sort_custom(_compare_datetime_dicts)
	future_times.sort()
	# Get at most the first 3 items
	var result = []
	for i in range(min(3, future_times.size())):
		result.append(future_times[i])
		
	for i in range(result.size()):
		result[i] = Time.get_datetime_dict_from_unix_time(result[i])
		
	return result

# Custom sort function to compare datetime dictionaries based on their Unix timestamps.
func _compare_datetime_dicts(a: Dictionary, b: Dictionary) -> int:
	var ts_a = Time.get_unix_time_from_datetime_dict(a)
	var ts_b = Time.get_unix_time_from_datetime_dict(b)
	if ts_a < ts_b:
		return -1
	elif ts_a > ts_b:
		return 1
	else:
		return 0
