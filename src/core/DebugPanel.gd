extends CanvasLayer

# =============================================================================
# DebugPanel.gd — In-editor testing overlay (remove from production export)
# Add as a child of your main scene during development only.
# Toggle visibility with F1.
# =============================================================================

@onready var label: Label = $Panel/VBox/Label
@onready var panel: Panel = $Panel

var _visible := true

func _ready() -> void:
	# Only active in debug builds
	if not OS.is_debug_build():
		queue_free()
		return
	GameManager.currency_changed.connect(_on_state_change)
	GameManager.earnings_per_second_changed.connect(_on_state_change)
	GameManager.phase_unlocked.connect(_on_phase_unlocked)
	_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # F1 or Escape
		_visible = !_visible
		panel.visible = _visible

func _on_state_change(_val = null) -> void:
	_refresh()

func _on_phase_unlocked(phase_name: String) -> void:
	print("[DEBUG] Phase unlocked: ", phase_name)
	_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	var gm: Node = GameManager
	var lines := [
		"=== DEBUG PANEL ===",
		"Currency:     $%.2f" % gm.currency,
		"Lifetime:     $%.2f" % gm.lifetime_earnings,
		"EPS:          $%.4f/s" % gm.earnings_per_second,
		"Prestige:     %d" % gm.prestige_count,
		"Phases:       %s" % str(gm.unlocked_phases),
		"",
		"--- Machines ---",
	]
	for machine_id in GameManager.MACHINE_DATA.keys():
		var state: Dictionary = gm.machine_states.get(machine_id, {})
		var owned: bool = state.get("owned", false)
		var tier: int = state.get("tier", 0)
		var eps: float = gm.get_machine_eps(machine_id)
		lines.append("%s: %s | T%d | $%.4f/s" % [
			machine_id, "OWNED" if owned else "---", tier, eps
		])
	lines.append("")
	lines.append("[F1] Toggle  [Buttons below] Cheats")
	label.text = "\n".join(lines)

# ---------------------------------------------------------------------------
# Cheat buttons — wire these up in the scene or call from GdUnit tests
# ---------------------------------------------------------------------------
func cheat_add_currency(amount: float) -> void:
	GameManager.currency += amount
	GameManager.currency_changed.emit(GameManager.currency)

func cheat_complete_phase(phase_name: String) -> void:
	# Force lifetime earnings to phase threshold
	var threshold: float = GameManager.PHASE_THRESHOLDS.get(phase_name, 0.0)
	GameManager.lifetime_earnings = threshold
	GameManager._check_phase_unlocks()

func cheat_simulate_offline(seconds: float) -> void:
	OfflineEarnings.simulate_offline(seconds)

func cheat_reset_save() -> void:
	SaveSystem.delete_save()
	get_tree().reload_current_scene()
