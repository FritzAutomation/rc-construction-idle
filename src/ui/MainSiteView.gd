extends Control

# =============================================================================
# MainSiteView.gd — Primary game screen controller
# =============================================================================

const MachinePanelScene := preload("res://src/ui/MachinePanel.tscn")

@onready var currency_label: Label = %CurrencyLabel
@onready var eps_label: Label = %EpsLabel
@onready var phase_label: Label = %PhaseLabel
@onready var phase_progress: ProgressBar = %PhaseProgressBar
@onready var machine_list: VBoxContainer = %MachineList
@onready var prestige_button: Button = %PrestigeButton
@onready var cheat_button: Button = %CheatButton
@onready var prestige_label: Label = %PrestigeLabel

var _float_timer: float = 0.0
const FLOAT_INTERVAL := 2.0  # seconds between floating text

func _ready() -> void:
	# Apply theme
	theme = GameTheme.create_theme()
	currency_label.add_theme_color_override("font_color", GameTheme.ACCENT_YELLOW)
	eps_label.add_theme_color_override("font_color", GameTheme.TEXT_SECONDARY)
	phase_label.add_theme_color_override("font_color", GameTheme.TEXT_SECONDARY)
	prestige_label.add_theme_color_override("font_color", GameTheme.BTN_PRESTIGE)

	# Style prestige button
	var prestige_styles: Dictionary = GameTheme.make_prestige_button_styles()
	for state in prestige_styles:
		prestige_button.add_theme_stylebox_override(state, prestige_styles[state])

	# Connect signals
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.earnings_per_second_changed.connect(_on_eps_changed)
	GameManager.phase_unlocked.connect(_on_phase_unlocked)
	GameManager.machine_purchased.connect(_on_machine_purchased)
	prestige_button.pressed.connect(_on_prestige_pressed)
	cheat_button.pressed.connect(_on_cheat_pressed)
	GameManager.prestige_completed.connect(_on_prestige_completed)

	cheat_button.visible = OS.is_debug_build()

	# Initial display
	_on_currency_changed(GameManager.currency)
	_on_eps_changed(GameManager.earnings_per_second)
	_update_phase_display()
	_update_prestige_button()
	_update_prestige_label()
	_build_machine_panels()

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_currency_changed(new_amount: float) -> void:
	currency_label.text = Format.currency(new_amount)

func _on_eps_changed(new_eps: float) -> void:
	eps_label.text = Format.currency_per_sec(new_eps)

func _on_phase_unlocked(phase_name: String) -> void:
	_update_phase_display()
	_show_phase_banner(phase_name)

func _on_machine_purchased(_machine_id: String) -> void:
	_spawn_floating_text("+1 " + GameManager.MACHINE_DATA[_machine_id]["name"] + "!")

# ---------------------------------------------------------------------------
# Phase progress
# ---------------------------------------------------------------------------
func _update_phase_display() -> void:
	var next_phase := _get_next_phase()
	if next_phase == "":
		phase_label.text = "All phases complete!"
		phase_progress.value = phase_progress.max_value
	else:
		var threshold: float = GameManager.PHASE_THRESHOLDS[next_phase]
		var progress: float = GameManager.lifetime_earnings
		var phase_display := next_phase.replace("_", " ").capitalize()
		phase_label.text = "%s — %s / %s" % [phase_display, Format.currency(progress), Format.currency(threshold)]
		phase_progress.max_value = threshold
		phase_progress.value = minf(progress, threshold)

func _get_next_phase() -> String:
	var order: Array = ["site_clear", "foundation", "pour", "frame", "complete"]
	for phase in order:
		if not GameManager.is_phase_unlocked(phase):
			return phase
	return ""

func _process(delta: float) -> void:
	_update_phase_display()
	_update_prestige_button()

	# Floating earnings text
	if GameManager.earnings_per_second > 0.0:
		_float_timer += delta
		if _float_timer >= FLOAT_INTERVAL:
			_float_timer = 0.0
			var earned := GameManager.earnings_per_second * FLOAT_INTERVAL
			_spawn_floating_text("+" + Format.currency(earned))

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
func _update_prestige_label() -> void:
	if GameManager.prestige_count > 0:
		var bonus: float = GameManager.PRESTIGE_BONUSES[GameManager.prestige_count] * 100
		prestige_label.text = "⭐ Prestige %d — +%.0f%% bonus" % [GameManager.prestige_count, bonus]
		prestige_label.visible = true
	else:
		prestige_label.visible = false

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
	_update_prestige_label()

# ---------------------------------------------------------------------------
# Visual feedback
# ---------------------------------------------------------------------------
func _spawn_floating_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", GameTheme.ACCENT_YELLOW)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(
		currency_label.global_position.x + currency_label.size.x * 0.5 - 40,
		currency_label.global_position.y + currency_label.size.y
	)
	add_child(label)

	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 50, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func _show_phase_banner(phase_name: String) -> void:
	var banner := Label.new()
	var display := phase_name.replace("_", " ").capitalize()
	banner.text = "🔓 %s Unlocked!" % display
	banner.add_theme_font_size_override("font_size", 28)
	banner.add_theme_color_override("font_color", GameTheme.ACCENT_YELLOW)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.anchors_preset = Control.PRESET_CENTER_TOP
	banner.position.y = 100
	banner.modulate.a = 0.0
	add_child(banner)

	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(banner.queue_free)

# ---------------------------------------------------------------------------
# Cheat (debug only)
# ---------------------------------------------------------------------------
func _on_cheat_pressed() -> void:
	GameManager._add_currency(100_000_000.0)
