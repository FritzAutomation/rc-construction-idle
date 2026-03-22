extends AcceptDialog

# =============================================================================
# OfflinePopup.gd — "Welcome back" dialog showing offline earnings
# Listens to OfflineEarnings.offline_earnings_ready signal.
# =============================================================================

func _ready() -> void:
	OfflineEarnings.offline_earnings_ready.connect(_on_offline_earnings_ready)
	title = "Welcome Back!"

func _on_offline_earnings_ready(amount: float, seconds: float) -> void:
	if amount <= 0.0:
		return
	var minutes := int(seconds) / 60
	var hours := minutes / 60
	minutes = minutes % 60
	var time_text: String
	if hours > 0:
		time_text = "%dh %dm" % [hours, minutes]
	else:
		time_text = "%dm" % minutes
	dialog_text = "You were away for %s.\n\nYou earned $%.2f!" % [time_text, amount]
	popup_centered(Vector2i(300, 150))
