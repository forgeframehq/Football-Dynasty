extends Node
# Static database (real leagues, clubs and players) and name pools.

var raw = null
var names: Dictionary = {}


func load_db() -> Dictionary:
	if raw != null:
		return raw
	var f = FileAccess.open("res://data/db.json", FileAccess.READ)
	raw = JSON.parse_string(f.get_as_text())
	f.close()
	names = raw["names"]
	return raw


func random_name(nat: String, rng: RandomNumberGenerator) -> Array:
	load_db()
	var pool = names.get(nat, null)
	if pool == null:
		pool = names["England"]
	return [pool["f"][rng.randi() % pool["f"].size()], pool["l"][rng.randi() % pool["l"].size()]]
