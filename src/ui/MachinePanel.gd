extends PanelContainer

# =============================================================================
# MachinePanel.gd — Reusable buy/upgrade row for a single machine
# =============================================================================

@onready var name_label: Label = %MachineName
@onready var status_label: Label = %StatusLabel
@onready var eps_label: Label = %MachineEps
@onready var buy_button: Button = %BuyButton
@onready var upgrade_button: Button = %UpgradeButton

var machine_id: String = ""

func setup(id: String) -> void:
	machine_id = id
	var data: Dictionary = GameManager.MACHINE_DATA[id]
	name_label.text = data["name"]
	refresh()

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
			upgrade_button.text = "Upgrade — %s" % Format.currency(cost)
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
		buy_button.text = "Buy — %s" % Format.currency(data["base_cost"])
		buy_button.disabled = GameManager.currency < data["base_cost"]
		buy_button.show()

func _is_visible_to_player(data: Dictionary) -> bool:
	var phase: String = data["unlock_phase"]
	if phase == "":
		return true
	return GameManager.is_phase_unlocked(phase)

func _on_buy_button_pressed() -> void:
	if GameManager.purchase_machine(machine_id):
		_flash(Color.GREEN)

func _on_upgrade_button_pressed() -> void:
	if GameManager.upgrade_machine(machine_id):
		_flash(Color.CYAN)

func _flash(color: Color) -> void:
	var tween := create_tween()
	modulate = color
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
