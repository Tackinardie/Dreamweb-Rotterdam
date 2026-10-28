class_name JsonLezer
extends RefCounted
## Leest JSON-bestanden. Godot parst alle getallen als float; hier worden gehele getallen weer int.


static func lees(pad: String) -> Variant:
	if not FileAccess.file_exists(pad):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(pad)) != OK:
		printerr("JSON-fout in %s regel %d: %s" % [pad, json.get_error_line(), json.get_error_message()])
		return null
	return normaliseer(json.data)


static func normaliseer(x: Variant) -> Variant:
	match typeof(x):
		TYPE_FLOAT:
			var f: float = x
			if f == floorf(f) and absf(f) < 1.0e15:
				return int(f)
			return f
		TYPE_DICTIONARY:
			var d: Dictionary = {}
			for k: Variant in (x as Dictionary):
				d[k] = normaliseer((x as Dictionary)[k])
			return d
		TYPE_ARRAY:
			var a: Array = []
			for v: Variant in (x as Array):
				a.append(normaliseer(v))
			return a
	return x


## Alle .json-bestanden onder een map (recursief), gesorteerd.
static func lijst_json(map: String) -> PackedStringArray:
	var uit := PackedStringArray()
	for f in DirAccess.get_files_at(map):
		if f.ends_with(".json"):
			uit.append(map.path_join(f))
	for d in DirAccess.get_directories_at(map):
		uit.append_array(lijst_json(map.path_join(d)))
	uit.sort()
	return uit
