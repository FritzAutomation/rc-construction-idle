extends Label

# =============================================================================
# FloatingText.gd — Floating "+$X" indicator that fades and rises
# =============================================================================

func start(amount_text: String, start_pos: Vector2) -> void:
	text = amount_text
	position = start_pos
	modulate = GameTheme.ACCENT_YELLOW
	modulate.a = 1.0

	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", start_pos.y - 60, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
