extends Node

signal updated_data

var MainlineEntry: LineEntry

# Applies the system timezone offset to a datetime dictionary.
func apply_timezone_offset(datetime_dict: Dictionary) -> Dictionary:
	var unix_time: int = Time.get_unix_time_from_datetime_dict(datetime_dict)
	unix_time += Time.get_time_zone_from_system().bias * 60
	return Time.get_datetime_dict_from_unix_time(unix_time)

# --- Inner Classes ---

class TimetableEntry:
	var dateTime: Dictionary
	var runID: String
	var vehicleID: String
	var direction: String

	func _init(data: Dictionary) -> void:
		# Parse date string, then offset time
		var raw_date = Time.get_datetime_dict_from_datetime_string(data.get("dateTime", ""), false)
		dateTime = Globals.apply_timezone_offset(raw_date)
		
		runID = data.get("runID", "")
		direction = data.get("direction", "")
		
		# Safer check for vehicleID
		var v_id = data.get("vehicleID")
		if v_id != null:
			vehicleID = str(v_id)
		else:
			vehicleID = "NONE"

class LineEntry:
	var lineID: String
	var locationID: String
	var day: Dictionary
	var timetable: Array[TimetableEntry] = []

	func _init(data: Dictionary) -> void:
		lineID = data.get("lineID", "")
		locationID = data.get("locationID", "")
		
		var raw_day = Time.get_datetime_dict_from_datetime_string(data.get("day", ""), false)
		day = Globals.apply_timezone_offset(raw_day)
		
		var tt_array = data.get("timetable", [])
		if tt_array is Array:
			for tt_data in tt_array:
				timetable.append(TimetableEntry.new(tt_data))

# --- Helper Functions ---

# Returns an array of the 3 datetime dictionaries that are in the future (closest first)
func get_next_three_datetimes(times: Array[TimetableEntry], current_datetime: Dictionary = Time.get_datetime_dict_from_system(false)) -> Array[Dictionary]:
	var current_ts: int = Time.get_unix_time_from_datetime_dict(current_datetime)
	var future_timestamps: Array[int] = []
	
	# 1. Convert to Unix and Filter
	for entry in times:
		var entry_ts: int = Time.get_unix_time_from_datetime_dict(entry.dateTime)
		if entry_ts > current_ts:
			future_timestamps.append(entry_ts)
	
	# 2. Sort integers
	future_timestamps.sort()
	
	# 3. Slice top 3 and convert back to Dictionaries
	var result: Array[Dictionary] = []
	var limit: int = min(3, future_timestamps.size())
	
	for i in range(limit):
		result.append(Time.get_datetime_dict_from_unix_time(future_timestamps[i]))
		
	return result
