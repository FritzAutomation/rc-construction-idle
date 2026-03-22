extends Node

# =============================================================================
# SaveSystem.gd — File persistence for all game state
# Autoload name: SaveSystem
# =============================================================================

const SAVE_PATH := "user://savegame.json"
const AUTO_SAVE_INTERVAL := 30.0  # seconds

var _auto_save_timer: float = 0.0

func _ready() -> void:
	# Also save when app is about to close or lose focus
	get_tree().auto_accept_quit = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()

func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		save_game()

func save_game() -> void:
	var data := GameManager.get_save_data()
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_error("SaveSystem: Failed to open save file for writing.")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveSystem: Failed to open save file for reading.")
		return
	var json_string := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_string)
	if parsed == null:
		push_error("SaveSystem: Failed to parse save JSON.")
		return
	var data: Dictionary = parsed
	var elapsed: float = _calculate_offline_seconds(data)
	GameManager.apply_save_data(data)
	if elapsed > 10.0:
		OfflineEarnings.trigger(elapsed)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _calculate_offline_seconds(data: Dictionary) -> float:
	var last_ts: float = data.get("last_save_timestamp", 0.0)
	if last_ts == 0.0:
		return 0.0
	var now := Time.get_unix_time_from_system()
	return maxf(now - last_ts, 0.0)
