extends Control

# =============================================================================
# MainSiteView.gd — Primary game screen controller
# Displays currency, earnings/sec, phase progress, and machine panels.
# All state changes go through GameManager; UI reacts via signals.
# =============================================================================

const MachinePanelScene := preload("res://src/ui/MachinePanel.tscn")

@onready var currency_label: Label = %CurrencyLabel
@onready var eps_label: Label = %EpsLabel
@onready var phase_label: Label = %PhaseLabel
@onready var machine_list: VBoxContainer = %MachineList
@onready var prestige_button: Button = %PrestigeButton
@onready var cheat_button: Button = %CheatButton

func _ready() -> void:
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.earnings_per_second_changed.connect(_on_eps_changed)
	GameManager.phase_unlocked.connect(_on_phase_unlocked)

	prestige_button.pressed.connect(_on_prestige_pressed)
	cheat_button.pressed.connect(_on_cheat_pressed)
	GameManager.prestige_completed.connect(_on_prestige_completed)

	# Hide cheat button in release builds
	cheat_button.visible = OS.is_debug_build()

	_on_currency_changed(GameManager.currency)
	_on_eps_changed(GameManager.earnings_per_second)
	_update_phase_display()
	_update_prestige_button()
	_build_machine_panels()

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_currency_changed(new_amount: float) -> void:
	currency_label.text = Format.currency(new_amount)

func _on_eps_changed(new_eps: float) -> void:
	eps_label.text = Format.currency_per_sec(new_eps)

func _on_phase_unlocked(_phase_name: String) -> void:
	_update_phase_display()
	_flash_label(phase_label, Color.GOLD)

# ---------------------------------------------------------------------------
# Phase progress
# ---------------------------------------------------------------------------
func _update_phase_display() -> void:
	var next_phase := _get_next_phase()
	if next_phase == "":
		phase_label.text = "All phases complete!"
	else:
		var threshold: float = GameManager.PHASE_THRESHOLDS[next_phase]
		var progress: float = GameManager.lifetime_earnings
		var phase_display := next_phase.replace("_", " ").capitalize()
		phase_label.text = "%s — %s / %s" % [phase_display, Format.currency(progress), Format.currency(threshold)]

func _get_next_phase() -> String:
	var order: Array = ["site_clear", "foundation", "pour", "frame", "complete"]
	for phase in order:
		if not GameManager.is_phase_unlocked(phase):
			return phase
	return ""

func _process(_delta: float) -> void:
	_update_phase_display()
	_update_prestige_button()

# ---------------------------------------------------------------------------
# Machine panels
# ---------------------------------------------------------------------------
func _build_machine_panels() -> void:
	var order: Array = ["dump_truck", "skid_steer", "excavator", "concrete_mixer", "tower_crane", "compactor"]
	for machine_id in order:
		var panel: PanelContainer = MachinePanelScene.instantiate()
		machine_list.add_child(panel)
		panel.setup(machine_id)

# ---------------------------------------------------------------------------
# Prestige
# ---------------------------------------------------------------------------
func _update_prestige_button() -> void:
	if GameManager.can_prestige():
		prestige_button.visible = true
		var next := GameManager.prestige_count + 1
		var bonus: float = GameManager.PRESTIGE_BONUSES[next] * 100
		prestige_button.text = "PRESTIGE — +%.0f%% earnings bonus" % bonus
	else:
		prestige_button.visible = false

func _on_prestige_pressed() -> void:
	GameManager.do_prestige()

func _on_prestige_completed(_prestige_count: int) -> void:
	for child in machine_list.get_children():
		child.queue_free()
	_build_machine_panels()

# ---------------------------------------------------------------------------
# Visual feedback
# ---------------------------------------------------------------------------
func _flash_label(label: Label, color: Color) -> void:
	var tween := create_tween()
	label.modulate = color
	tween.tween_property(label, "modulate", Color.WHITE, 0.6)

# ---------------------------------------------------------------------------
# Cheat (debug only)
# ---------------------------------------------------------------------------
func _on_cheat_pressed() -> void:
	GameManager._add_currency(100_000_000.0)
