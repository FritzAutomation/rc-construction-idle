extends Node

# =============================================================================
# GameTheme.gd — Builds and returns the game's visual theme
# =============================================================================

# Construction palette
const BG_DARK := Color("0f1923")
const BG_PANEL := Color("1a2a3a")
const BG_PANEL_HOVER := Color("243444")
const ACCENT_YELLOW := Color("f5a623")
const ACCENT_ORANGE := Color("e8751a")
const TEXT_PRIMARY := Color("f0f0f0")
const TEXT_SECONDARY := Color("8899aa")
const BTN_BUY := Color("2d8a4e")
const BTN_BUY_HOVER := Color("36a35c")
const BTN_BUY_DISABLED := Color("1a3a28")
const BTN_UPGRADE := Color("2a6ca8")
const BTN_UPGRADE_HOVER := Color("3580c0")
const BTN_UPGRADE_DISABLED := Color("1a2a40")
const BTN_PRESTIGE := Color("8b5cf6")
const BTN_PRESTIGE_HOVER := Color("a078ff")
const SEPARATOR_COLOR := Color("2a3a4a")

static func create_theme() -> Theme:
	var theme := Theme.new()

	# Default font color
	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_color("font_color", "Button", TEXT_PRIMARY)

	# Panel styling
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = BG_PANEL
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# Button base
	var btn_normal := _make_button_style(BTN_BUY)
	var btn_hover := _make_button_style(BTN_BUY_HOVER)
	var btn_pressed := _make_button_style(BTN_BUY.darkened(0.2))
	var btn_disabled := _make_button_style(BTN_BUY_DISABLED)
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_color("font_disabled_color", "Button", TEXT_SECONDARY)

	# Separator
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = SEPARATOR_COLOR
	sep_style.content_margin_top = 1
	sep_style.content_margin_bottom = 1
	theme.set_stylebox("separator", "HSeparator", sep_style)
	theme.set_constant("separation", "HSeparator", 8)

	# ProgressBar
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color("0a1520")
	pb_bg.corner_radius_top_left = 4
	pb_bg.corner_radius_top_right = 4
	pb_bg.corner_radius_bottom_left = 4
	pb_bg.corner_radius_bottom_right = 4
	theme.set_stylebox("background", "ProgressBar", pb_bg)

	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = ACCENT_YELLOW
	pb_fill.corner_radius_top_left = 4
	pb_fill.corner_radius_top_right = 4
	pb_fill.corner_radius_bottom_left = 4
	pb_fill.corner_radius_bottom_right = 4
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	# ScrollContainer - invisible scrollbar background
	var scroll_bg := StyleBoxEmpty.new()
	theme.set_stylebox("scroll", "VScrollBar", scroll_bg)

	var scroll_grabber := StyleBoxFlat.new()
	scroll_grabber.bg_color = Color("3a4a5a")
	scroll_grabber.corner_radius_top_left = 3
	scroll_grabber.corner_radius_top_right = 3
	scroll_grabber.corner_radius_bottom_left = 3
	scroll_grabber.corner_radius_bottom_right = 3
	theme.set_stylebox("grabber", "VScrollBar", scroll_grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", scroll_grabber)
	theme.set_stylebox("grabber_pressed", "VScrollBar", scroll_grabber)

	return theme

static func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func make_buy_button_styles() -> Dictionary:
	return {
		"normal": _make_button_style(BTN_BUY),
		"hover": _make_button_style(BTN_BUY_HOVER),
		"pressed": _make_button_style(BTN_BUY.darkened(0.2)),
		"disabled": _make_button_style(BTN_BUY_DISABLED),
	}

static func make_upgrade_button_styles() -> Dictionary:
	return {
		"normal": _make_button_style(BTN_UPGRADE),
		"hover": _make_button_style(BTN_UPGRADE_HOVER),
		"pressed": _make_button_style(BTN_UPGRADE.darkened(0.2)),
		"disabled": _make_button_style(BTN_UPGRADE_DISABLED),
	}

static func make_prestige_button_styles() -> Dictionary:
	return {
		"normal": _make_button_style(BTN_PRESTIGE),
		"hover": _make_button_style(BTN_PRESTIGE_HOVER),
		"pressed": _make_button_style(BTN_PRESTIGE.darkened(0.2)),
		"disabled": _make_button_style(BTN_PRESTIGE.darkened(0.4)),
	}
