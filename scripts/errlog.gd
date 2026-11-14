extends Logger
# Catches script errors and engine warnings while the game runs, so problems on a phone can be read back
# afterwards (Settings > Diagnostics). Kept to the last 60 entries in user://errors.log.

var items: Array = []
var lock := Mutex.new()
var total := 0


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
	var kind = ["Error", "Warning", "Script", "Shader"][clamp(error_type, 0, 3)]
	var text = rationale if rationale != "" else code
	var entry = "%s  %s: %s  (%s:%d %s)" % [Time.get_datetime_string_from_system(false, true), kind, text, file.get_file(), line, function]
	lock.lock()
	total += 1
	if items.is_empty() or items[-1].substr(20) != entry.substr(20):
		items.append(entry)
		if items.size() > 60:
			items.pop_front()
	lock.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass


func snapshot() -> Array:
	lock.lock()
	var out = items.duplicate()
	lock.unlock()
	return out


func save():
	var f = FileAccess.open("user://errors.log", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(snapshot()))


func clear():
	lock.lock()
	items.clear()
	total = 0
	lock.unlock()
	save()
