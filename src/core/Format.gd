extends RefCounted
class_name Format

# =============================================================================
# Format.gd — Static number formatting helpers
# =============================================================================

const SUFFIXES: Array = [
	{"threshold": 1_000_000_000_000.0, "suffix": "T"},
	{"threshold": 1_000_000_000.0, "suffix": "B"},
	{"threshold": 1_000_000.0, "suffix": "M"},
	{"threshold": 1_000.0, "suffix": "K"},
]

static func currency(value: float) -> String:
	var abs_val := absf(value)
	for entry in SUFFIXES:
		if abs_val >= entry["threshold"]:
			var scaled: float = value / entry["threshold"]
			return "$%.1f%s" % [scaled, entry["suffix"]]
	return "$%.2f" % value

static func currency_per_sec(value: float) -> String:
	return "%s/sec" % currency(value)
