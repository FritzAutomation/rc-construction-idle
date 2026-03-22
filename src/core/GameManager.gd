extends Node

# =============================================================================
# GameManager.gd — Central Game State Singleton
# Autoload name: GameManager
# =============================================================================
# Owns: currency, lifetime earnings, earnings/sec, machine states, phase state,
#       prestige level. All other systems read from and signal through here.
# =============================================================================

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal currency_changed(new_amount: float)
signal lifetime_earnings_changed(new_amount: float)
signal earnings_per_second_changed(new_eps: float)
signal machine_purchased(machine_id: String)
signal machine_upgraded(machine_id: String, tier: int)
signal phase_unlocked(phase_name: String)
signal prestige_completed(prestige_count: int)

# ---------------------------------------------------------------------------
# Economy Constants
# ---------------------------------------------------------------------------
const MAX_OFFLINE_SECONDS := 14400.0  # 4 hour cap

const PHASE_THRESHOLDS := {
	"site_clear": 500.0,
	"foundation": 25_000.0,
	"pour": 750_000.0,
	"frame": 20_000_000.0,
	"complete": 500_000_000.0,
}

const PRESTIGE_BONUSES: Array = [0.0, 0.25, 0.50, 1.00]

const UPGRADE_EARNINGS_MULTIPLIERS: Array = [1.0, 1.5, 2.0, 3.0]
const UPGRADE_COST_MULTIPLIERS: Array = [0.0, 2.0, 5.0, 20.0]

# ---------------------------------------------------------------------------
# Machine Definitions
# ---------------------------------------------------------------------------
const MACHINE_DATA := {
	"dump_truck": {
		"name": "Dump Truck",
		"base_eps": 0.10,
		"base_cost": 10.0,
		"unlock_phase": "",          # always available
	},
	"skid_steer": {
		"name": "Skid Steer",
		"base_eps": 0.60,
		"base_cost": 120.0,
		"unlock_phase": "site_clear",
	},
	"excavator": {
		"name": "Excavator",
		"base_eps": 4.00,
		"base_cost": 1300.0,
		"unlock_phase": "site_clear",
	},
	"concrete_mixer": {
		"name": "Concrete Mixer",
		"base_eps": 25.00,
		"base_cost": 14_000.0,
		"unlock_phase": "foundation",
	},
	"tower_crane": {
		"name": "Tower Crane",
		"base_eps": 150.00,
		"base_cost": 200_000.0,
		"unlock_phase": "pour",
	},
	"compactor": {
		"name": "Compactor",
		"base_eps": 1_000.00,
		"base_cost": 3_300_000.0,
		"unlock_phase": "frame",
	},
}

# ---------------------------------------------------------------------------
# Runtime State
# ---------------------------------------------------------------------------
var currency: float = 0.0
var lifetime_earnings: float = 0.0
var earnings_per_second: float = 0.0
var prestige_count: int = 0
var unlocked_phases: Array = []

# machine_states[machine_id] = { "owned": bool, "tier": int (0-3) }
var machine_states: Dictionary = {}

# ---------------------------------------------------------------------------
# Godot Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_init_machine_states()
	SaveSystem.load_game()
	_recalculate_eps()
	_check_phase_unlocks()

func _process(delta: float) -> void:
	if earnings_per_second > 0.0:
		_add_currency(earnings_per_second * delta)

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------
func _init_machine_states() -> void:
	for machine_id in MACHINE_DATA.keys():
		if not machine_states.has(machine_id):
			machine_states[machine_id] = {"owned": false, "tier": 0}

# ---------------------------------------------------------------------------
# Currency
# ---------------------------------------------------------------------------
func _add_currency(amount: float) -> void:
	currency += amount
	lifetime_earnings += amount
	currency_changed.emit(currency)
	lifetime_earnings_changed.emit(lifetime_earnings)
	_check_phase_unlocks()

func spend_currency(amount: float) -> bool:
	if currency < amount:
		return false
	currency -= amount
	currency_changed.emit(currency)
	return true

# ---------------------------------------------------------------------------
# Machines
# ---------------------------------------------------------------------------
func can_purchase(machine_id: String) -> bool:
	var data: Dictionary = MACHINE_DATA[machine_id]
	var state: Dictionary = machine_states[machine_id]
	if state["owned"]:
		return false
	if data["unlock_phase"] != "" and not data["unlock_phase"] in unlocked_phases:
		return false
	return currency >= data["base_cost"]

func purchase_machine(machine_id: String) -> bool:
	if not can_purchase(machine_id):
		return false
	var cost: float = MACHINE_DATA[machine_id]["base_cost"]
	if not spend_currency(cost):
		return false
	machine_states[machine_id]["owned"] = true
	machine_purchased.emit(machine_id)
	_recalculate_eps()
	SaveSystem.save_game()
	return true

func can_upgrade(machine_id: String) -> bool:
	var state: Dictionary = machine_states[machine_id]
	if not state["owned"]:
		return false
	if state["tier"] >= 3:
		return false
	return currency >= get_upgrade_cost(machine_id)

func upgrade_machine(machine_id: String) -> bool:
	if not can_upgrade(machine_id):
		return false
	var cost: float = get_upgrade_cost(machine_id)
	if not spend_currency(cost):
		return false
	machine_states[machine_id]["tier"] += 1
	var new_tier: int = machine_states[machine_id]["tier"]
	machine_upgraded.emit(machine_id, new_tier)
	_recalculate_eps()
	SaveSystem.save_game()
	return true

func get_upgrade_cost(machine_id: String) -> float:
	var state: Dictionary = machine_states[machine_id]
	var next_tier: int = state["tier"] + 1
	if next_tier > 3:
		return INF
	return MACHINE_DATA[machine_id]["base_cost"] * UPGRADE_COST_MULTIPLIERS[next_tier]

func get_machine_eps(machine_id: String) -> float:
	var state: Dictionary = machine_states[machine_id]
	if not state["owned"]:
		return 0.0
	var base: float = MACHINE_DATA[machine_id]["base_eps"]
	var tier_mult: float = UPGRADE_EARNINGS_MULTIPLIERS[state["tier"]]
	return base * tier_mult

# ---------------------------------------------------------------------------
# Earnings Per Second
# ---------------------------------------------------------------------------
func _recalculate_eps() -> void:
	var total: float = 0.0
	for machine_id in MACHINE_DATA.keys():
		total += get_machine_eps(machine_id)
	total *= _prestige_multiplier()
	earnings_per_second = total
	earnings_per_second_changed.emit(earnings_per_second)

func _prestige_multiplier() -> float:
	var idx := clampi(prestige_count, 0, PRESTIGE_BONUSES.size() - 1)
	return 1.0 + PRESTIGE_BONUSES[idx]

# ---------------------------------------------------------------------------
# Phase Unlocks
# ---------------------------------------------------------------------------
func _check_phase_unlocks() -> void:
	for phase_name in PHASE_THRESHOLDS.keys():
		if phase_name not in unlocked_phases:
			if lifetime_earnings >= PHASE_THRESHOLDS[phase_name]:
				unlocked_phases.append(phase_name)
				phase_unlocked.emit(phase_name)

func is_phase_unlocked(phase_name: String) -> bool:
	return phase_name in unlocked_phases

# ---------------------------------------------------------------------------
# Prestige
# ---------------------------------------------------------------------------
func can_prestige() -> bool:
	return is_phase_unlocked("complete") and prestige_count < 3

func do_prestige() -> void:
	if not can_prestige():
		return
	prestige_count += 1
	# Reset progress but keep prestige count
	currency = 0.0
	lifetime_earnings = 0.0
	unlocked_phases.clear()
	for machine_id in machine_states.keys():
		machine_states[machine_id] = {"owned": false, "tier": 0}
	_recalculate_eps()
	prestige_completed.emit(prestige_count)
	SaveSystem.save_game()

# ---------------------------------------------------------------------------
# Offline Earnings (called by OfflineEarnings.gd on resume)
# ---------------------------------------------------------------------------
func apply_offline_earnings(elapsed_seconds: float) -> float:
	var capped := minf(elapsed_seconds, MAX_OFFLINE_SECONDS)
	var earned := earnings_per_second * capped
	if earned > 0.0:
		_add_currency(earned)
	return earned

# ---------------------------------------------------------------------------
# Save / Load helpers (called by SaveSystem)
# ---------------------------------------------------------------------------
func get_save_data() -> Dictionary:
	return {
		"currency": currency,
		"lifetime_earnings": lifetime_earnings,
		"prestige_count": prestige_count,
		"unlocked_phases": unlocked_phases,
		"machine_states": machine_states,
		"last_save_timestamp": Time.get_unix_time_from_system(),
	}

func apply_save_data(data: Dictionary) -> void:
	currency = data.get("currency", 0.0)
	lifetime_earnings = data.get("lifetime_earnings", 0.0)
	prestige_count = data.get("prestige_count", 0)
	unlocked_phases = data.get("unlocked_phases", [])
	var saved_machines: Dictionary = data.get("machine_states", {})
	for machine_id in saved_machines.keys():
		if machine_states.has(machine_id):
			machine_states[machine_id] = saved_machines[machine_id]
