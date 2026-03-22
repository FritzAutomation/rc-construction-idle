extends PanelContainer

# =============================================================================
# MachinePanel.gd — Reusable buy/upgrade row for a single machine
# =============================================================================

signal buy_pressed(machine_id: String)
signal upgrade_pressed(machine_id: String)

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
		eps_label.text = "$%.2f/sec" % current_eps
		status_label.text = "Tier %d" % state["tier"] if state["tier"] > 0 else "Owned"
		buy_button.hide()

		if state["tier"] < 3:
			var cost: float = GameManager.get_upgrade_cost(machine_id)
			upgrade_button.text = "Upgrade — $%.2f" % cost
			upgrade_button.disabled = GameManager.currency < cost
			upgrade_button.show()
		else:
			upgrade_button.text = "MAX"
			upgrade_button.disabled = true
			upgrade_button.show()
	else:
		eps_label.text = "$%.2f/sec" % data["base_eps"]
		status_label.text = ""
		upgrade_button.hide()
		buy_button.text = "Buy — $%.2f" % data["base_cost"]
		buy_button.disabled = GameManager.currency < data["base_cost"]
		buy_button.show()

func _is_visible_to_player(data: Dictionary) -> bool:
	var phase: String = data["unlock_phase"]
	if phase == "":
		return true
	return GameManager.is_phase_unlocked(phase)

func _on_buy_button_pressed() -> void:
	GameManager.purchase_machine(machine_id)

func _on_upgrade_button_pressed() -> void:
	GameManager.upgrade_machine(machine_id)
