class_name StartOpties
extends RefCounted
## Opdrachtregel na `--`: `--meet <kamer>`, `--stand vol|licht`, `--kamer <id>`, `--foto <pad.png>`, `--frames <n>`, `--spatie` (contouren aan, voor QA).
## Zowel `--naam waarde` als `--naam=waarde`.


static func parse(args: PackedStringArray) -> Dictionary:
	var uit: Dictionary = {}
	var i: int = 0
	while i < args.size():
		var a: String = args[i]
		i += 1
		if not a.begins_with("--"):
			continue
		var naam: String = a.substr(2)
		if naam.contains("="):
			var kv: PackedStringArray = naam.split("=", true, 1)
			uit[kv[0]] = kv[1]
		elif i < args.size() and not args[i].begins_with("--"):
			uit[naam] = args[i]
			i += 1
		else:
			uit[naam] = "true"
	return uit
