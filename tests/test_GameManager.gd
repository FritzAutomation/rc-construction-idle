extends GdUnitTestSuite

# =============================================================================
# test_GameManager.gd — Unit tests for GameManager core logic
# Requires: GdUnit4 plugin (install from Godot AssetLib)
# Run: GdUnit4 panel in editor → Run All, or Ctrl+Shift+F6
# =============================================================================

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _reset_game_manager() -> void:
	GameManager.currency = 0.0
	GameManager.lifetime_earnings = 0.0
	GameManager.prestige_count = 0
	GameManager.unlocked_phases.clear()
	GameManager._init_machine_states()
	GameManager._recalculate_eps()

# ---------------------------------------------------------------------------
# Currency Tests
# ---------------------------------------------------------------------------
func test_initial_currency_is_zero() -> void:
	_reset_game_manager()
	assert_float(GameManager.currency).is_equal(0.0)

func test_spend_currency_succeeds_when_sufficient() -> void:
	_reset_game_manager()
	GameManager.currency = 100.0
	var result := GameManager.spend_currency(50.0)
	assert_bool(result).is_true()
	assert_float(GameManager.currency).is_equal(50.0)

func test_spend_currency_fails_when_insufficient() -> void:
	_reset_game_manager()
	GameManager.currency = 10.0
	var result := GameManager.spend_currency(50.0)
	assert_bool(result).is_false()
	assert_float(GameManager.currency).is_equal(10.0)  # unchanged

# ---------------------------------------------------------------------------
# Machine Purchase Tests
# ---------------------------------------------------------------------------
func test_dump_truck_purchasable_at_start() -> void:
	_reset_game_manager()
	GameManager.currency = 10.0
	assert_bool(GameManager.can_purchase("dump_truck")).is_true()

func test_dump_truck_not_purchasable_without_funds() -> void:
	_reset_game_manager()
	GameManager.currency = 0.0
	assert_bool(GameManager.can_purchase("dump_truck")).is_false()

func test_purchase_dump_truck_deducts_cost() -> void:
	_reset_game_manager()
	GameManager.currency = 100.0
	GameManager.purchase_machine("dump_truck")
	assert_float(GameManager.currency).is_equal(90.0)  # 100 - 10 base cost

func test_cannot_purchase_machine_twice() -> void:
	_reset_game_manager()
	GameManager.currency = 1000.0
	GameManager.purchase_machine("dump_truck")
	assert_bool(GameManager.can_purchase("dump_truck")).is_false()

func test_locked_machine_not_purchasable_before_phase() -> void:
	_reset_game_manager()
	GameManager.currency = 9999.0
	# skid_steer requires site_clear phase
	assert_bool(GameManager.can_purchase("skid_steer")).is_false()

func test_locked_machine_purchasable_after_phase_unlock() -> void:
	_reset_game_manager()
	GameManager.currency = 9999.0
	GameManager.unlocked_phases.append("site_clear")
	assert_bool(GameManager.can_purchase("skid_steer")).is_true()

# ---------------------------------------------------------------------------
# Earnings Per Second Tests
# ---------------------------------------------------------------------------
func test_eps_is_zero_with_no_machines() -> void:
	_reset_game_manager()
	assert_float(GameManager.earnings_per_second).is_equal(0.0)

func test_eps_matches_dump_truck_base_after_purchase() -> void:
	_reset_game_manager()
	GameManager.currency = 100.0
	GameManager.purchase_machine("dump_truck")
	assert_float(GameManager.earnings_per_second).is_equal_approx(0.10, 0.001)

# ---------------------------------------------------------------------------
# Upgrade Tests
# ---------------------------------------------------------------------------
func test_upgrade_increases_eps() -> void:
	_reset_game_manager()
	GameManager.currency = 10000.0
	GameManager.purchase_machine("dump_truck")
	var eps_before := GameManager.earnings_per_second
	GameManager.upgrade_machine("dump_truck")  # tier 1: 1.5x
	assert_float(GameManager.earnings_per_second).is_greater(eps_before)

func test_cannot_upgrade_beyond_tier_3() -> void:
	_reset_game_manager()
	GameManager.currency = 999_999.0
	GameManager.purchase_machine("dump_truck")
	GameManager.upgrade_machine("dump_truck")  # tier 1
	GameManager.upgrade_machine("dump_truck")  # tier 2
	GameManager.upgrade_machine("dump_truck")  # tier 3
	assert_bool(GameManager.can_upgrade("dump_truck")).is_false()

# ---------------------------------------------------------------------------
# Phase Unlock Tests
# ---------------------------------------------------------------------------
func test_site_clear_unlocks_at_500_lifetime_earnings() -> void:
	_reset_game_manager()
	GameManager.lifetime_earnings = 499.0
	GameManager._check_phase_unlocks()
	assert_bool(GameManager.is_phase_unlocked("site_clear")).is_false()
	GameManager.lifetime_earnings = 500.0
	GameManager._check_phase_unlocks()
	assert_bool(GameManager.is_phase_unlocked("site_clear")).is_true()

# ---------------------------------------------------------------------------
# Offline Earnings Tests
# ---------------------------------------------------------------------------
func test_offline_earnings_capped_at_4_hours() -> void:
	_reset_game_manager()
	GameManager.currency = 100.0
	GameManager.purchase_machine("dump_truck")  # 0.10/s
	var earned := GameManager.apply_offline_earnings(99999.0)  # way over cap
	var expected := 0.10 * GameManager.MAX_OFFLINE_SECONDS
	assert_float(earned).is_equal_approx(expected, 0.01)

func test_offline_earnings_within_cap() -> void:
	_reset_game_manager()
	GameManager.currency = 100.0
	GameManager.purchase_machine("dump_truck")  # 0.10/s
	var earned := GameManager.apply_offline_earnings(600.0)  # 10 minutes
	assert_float(earned).is_equal_approx(60.0, 0.01)  # 0.10 * 600

# ---------------------------------------------------------------------------
# Prestige Tests
# ---------------------------------------------------------------------------
func test_prestige_not_available_before_complete_phase() -> void:
	_reset_game_manager()
	assert_bool(GameManager.can_prestige()).is_false()

func test_prestige_resets_currency_and_machines() -> void:
	_reset_game_manager()
	GameManager.currency = 999_999_999.0
	GameManager.unlocked_phases.append("complete")
	GameManager.purchase_machine("dump_truck")
	GameManager.do_prestige()
	assert_float(GameManager.currency).is_equal(0.0)
	assert_bool(GameManager.machine_states["dump_truck"]["owned"]).is_false()

func test_prestige_increments_count() -> void:
	_reset_game_manager()
	GameManager.currency = 999_999_999.0
	GameManager.unlocked_phases.append("complete")
	GameManager.do_prestige()
	assert_int(GameManager.prestige_count).is_equal(1)

func test_prestige_applies_multiplier_to_eps() -> void:
	_reset_game_manager()
	GameManager.prestige_count = 1  # +25%
	GameManager.currency = 100.0
	GameManager.purchase_machine("dump_truck")
	# 0.10 base * 1.25 prestige = 0.125
	assert_float(GameManager.earnings_per_second).is_equal_approx(0.125, 0.001)
