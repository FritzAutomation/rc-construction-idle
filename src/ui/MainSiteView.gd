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
@onready var cheat_button: Button = %CheatButton

func _ready() -> void:
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.earnings_per_second_changed.connect(_on_eps_changed)
	GameManager.phase_unlocked.connect(_on_phase_unlocked)

	cheat_button.pressed.connect(_on_cheat_pressed)

	_on_currency_changed(GameManager.currency)
	_on_eps_changed(GameManager.earnings_per_second)
	_update_phase_display()
	_build_machine_panels()

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_currency_changed(new_amount: float) -> void:
	currency_label.text = "$%.2f" % new_amount

func _on_eps_changed(new_eps: float) -> void:
	eps_label.text = "$%.2f/sec" % new_eps

func _on_phase_unlocked(_phase_name: String) -> void:
	_update_phase_display()

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
		phase_label.text = "%s — $%.0f / $%.0f" % [phase_display, progress, threshold]

func _get_next_phase() -> String:
	var order: Array = ["site_clear", "foundation", "pour", "frame", "complete"]
	for phase in order:
		if not GameManager.is_phase_unlocked(phase):
			return phase
	return ""

func _process(_delta: float) -> void:
	_update_phase_display()

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
# Cheat
# ---------------------------------------------------------------------------
func _on_cheat_pressed() -> void:
	GameManager._add_currency(100.0)
