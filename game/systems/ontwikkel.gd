class_name Ontwikkel
extends RefCounted
## Het enige script (naast klok.gd) dat de echte systeemtijd mag lezen: alleen voor ontwikkelbestanden
## (naam van het cue-logboek), nooit voor spellogica (KS-10).

## Ontwikkelbuild? Het geluidsvenster (F2) en het cue-logboek bestaan alleen als dit waar is.
static func actief() -> bool:
	return OS.is_debug_build() or OS.has_feature("ontwikkel")


## Tijdstempel voor bestandsnamen, bijv. 20260101-000700.
static func tijdstempel() -> String:
	return Time.get_datetime_string_from_system().replace("-", "").replace(":", "").replace("T", "-")
