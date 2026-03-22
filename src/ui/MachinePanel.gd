extends PanelContainer

# =============================================================================
# MachinePanel.gd — Reusable buy/upgrade row for a single machine
# =============================================================================

const MACHINE_ICONS := {
	"dump_truck": "🚛",
	"skid_steer": "🏗️",
	"excavator": "⛏️",
	"concrete_mixer": "🏭",
	"tower_crane": "🏗️",
	"compactor": "🚜",
}

const MACHINE_COLORS := {
	"dump_truck": Color("f5a623"),
	"skid_steer": Color("e8751a"),
	"excavator": Color("d4a017"),
	"concrete_mixer": Color("7a8b99"),
	"tower_crane": Color("c0392b"),
	"compactor": Color("2d8a4e"),
}

@onready var machine_icon: Label = %MachineIcon
@onready var name_label: Label = %MachineName
@onready var status_label: Label = %StatusLabel
@onready var eps_label: Label = %MachineEps
@onready var buy_button: Button = %BuyButton
@onready var upgrade_button: Button = %UpgradeButton

var machine_id: String = ""
var _working_tween: Tween = null

func setup(id: String) -> void:
	machine_id = id
	var data: Dictionary = GameManager.MACHINE_DATA[id]
	name_label.text = data["name"]

	# Machine icon
	machine_icon.text = MACHINE_ICONS.get(id, "🔧")

	# Icon panel background color
	var icon_panel: PanelContainer = machine_icon.get_parent()
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = MACHINE_COLORS.get(id, GameTheme.ACCENT_YELLOW).darkened(0.6)
	icon_style.corner_radius_top_left = 8
	icon_style.corner_radius_top_right = 8
	icon_style.corner_radius_bottom_left = 8
	icon_style.corner_radius_bottom_right = 8
	icon_panel.add_theme_stylebox_override("panel", icon_style)

	# Style buttons
	var buy_styles: Dictionary = GameTheme.make_buy_button_styles()
	for state in buy_styles:
		buy_button.add_theme_stylebox_override(state, buy_styles[state])

	var upgrade_styles: Dictionary = GameTheme.make_upgrade_button_styles()
	for state in upgrade_styles:
		upgrade_button.add_theme_stylebox_override(state, upgrade_styles[state])

	# Label colors
	status_label.add_theme_color_override("font_color", GameTheme.TEXT_SECONDARY)
	eps_label.add_theme_color_override("font_color", GameTheme.ACCENT_YELLOW)

	refresh()
	_start_working_animation()

func _process(_delta: float) -> void:
	if machine_id != "":
		refresh()

func refresh() -> void:
	var data: Dictionary = GameManager.MACHINE_DATA[machine_id]
	var state: Dictionary = GameManager.machine_states[machine_id]

	if not _is_visible_to_player(data):
		hide()
		return
	show()

	if state["owned"]:
		var current_eps: float = GameManager.get_machine_eps(machine_id)
		eps_label.text = Format.currency_per_sec(current_eps)
		status_label.text = "Tier %d" % state["tier"] if state["tier"] > 0 else "Owned"
		buy_button.hide()

		if state["tier"] < 3:
			var cost: float = GameManager.get_upgrade_cost(machine_id)
			upgrade_button.text = "Upgrade %s" % Format.currency(cost)
			upgrade_button.disabled = GameManager.currency < cost
			upgrade_button.show()
		else:
			upgrade_button.text = "MAX"
			upgrade_button.disabled = true
			upgrade_button.show()
	else:
		eps_label.text = Format.currency_per_sec(data["base_eps"])
		status_label.text = ""
		upgrade_button.hide()
		buy_button.text = "Buy %s" % Format.currency(data["base_cost"])
		buy_button.disabled = GameManager.currency < data["base_cost"]
		buy_button.show()

func _is_visible_to_player(data: Dictionary) -> bool:
	var phase: String = data["unlock_phase"]
	if phase == "":
		return true
	return GameManager.is_phase_unlocked(phase)

# ---------------------------------------------------------------------------
# Working animation — gentle pulse on icon when machine is owned
# ---------------------------------------------------------------------------
func _start_working_animation() -> void:
	GameManager.machine_purchased.connect(_on_any_machine_purchased)

func _on_any_machine_purchased(id: String) -> void:
	if id == machine_id:
		_begin_pulse()

func _begin_pulse() -> void:
	if _working_tween and _working_tween.is_valid():
		return
	_loop_pulse()

func _loop_pulse() -> void:
	var state: Dictionary = GameManager.machine_states[machine_id]
	if not state["owned"]:
		return
	_working_tween = create_tween().set_loops()
	var icon_panel: Control = machine_icon.get_parent()
	_working_tween.tween_property(icon_panel, "scale", Vector2(1.05, 1.05), 0.8).set_trans(Tween.TRANS_SINE)
	_working_tween.tween_property(icon_panel, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_SINE)

func _on_buy_button_pressed() -> void:
	if GameManager.purchase_machine(machine_id):
		_flash(Color.GREEN)
		_begin_pulse()

func _on_upgrade_button_pressed() -> void:
	if GameManager.upgrade_machine(machine_id):
		_flash(Color.CYAN)

func _flash(color: Color) -> void:
	var tween := create_tween()
	modulate = color
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
