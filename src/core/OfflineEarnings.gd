extends Node

# =============================================================================
# OfflineEarnings.gd — Handles idle income accumulated while app was closed
# Autoload name: OfflineEarnings
# =============================================================================

signal offline_earnings_ready(amount: float, seconds: float)

func trigger(elapsed_seconds: float) -> void:
	var earned: float = GameManager.apply_offline_earnings(elapsed_seconds)
	offline_earnings_ready.emit(earned, elapsed_seconds)

# Debug helper — call from DebugPanel or GdUnit tests
# e.g. OfflineEarnings.simulate_offline(3600) to simulate 1 hour away
func simulate_offline(seconds: float) -> void:
	trigger(seconds)
