extends SceneTree
## Одноразовый генератор theme.tres из кода (с регистрацией вариаций).
func _init() -> void:
	var theme := Theme.new()
	var font: FontFile = load("res://assets/fonts/NotoSans-Regular.ttf")
	var font_bold: FontFile = load("res://assets/fonts/NotoSans-Bold.ttf")
	theme.default_font = font
	theme.default_font_size = 15

	var panel := _sb(Color(1, 0.99, 0.96, 0.97), Color(0.85, 0.82, 0.72, 1), 2, 18, Color(0.1, 0.12, 0.18, 0.28), 14, Vector2(0, 5), Vector4(18, 14, 18, 14))
	var card := _sb(Color(1, 1, 1, 0.98), Color(0.85, 0.82, 0.72, 1), 2, 16, Color(0.1, 0.12, 0.18, 0.3), 16, Vector2(0, 6), Vector4(16, 12, 16, 12))
	var toast := _sb(Color(0.16, 0.12, 0.1, 0.94), Color(0.95, 0.45, 0.2, 1), 2, 12, null, 0, Vector2.ZERO, Vector4(16, 10, 16, 10))
	var btn := _sb(Color(1, 1, 1, 1), Color(0.82, 0.79, 0.68, 1), 2, 12, null, 0, Vector2.ZERO, Vector4(16, 8, 16, 8))
	var btn_hover := _sb(Color(0.96, 0.95, 0.89, 1), Color(0.7, 0.68, 0.55, 1), 2, 12, null, 0, Vector2.ZERO, Vector4(16, 8, 16, 8))
	var btn_pressed := _sb(Color(0.9, 0.89, 0.81, 1), Color(0.6, 0.58, 0.48, 1), 2, 12, null, 0, Vector2.ZERO, Vector4(16, 8, 16, 8))
	var primary := _sb(Color(0.086, 0.639, 0.29, 1), null, 0, 12, Color(0.05, 0.35, 0.16, 0.45), 8, Vector2(0, 3), Vector4(20, 10, 20, 10))
	var primary_hover := _sb(Color(0.075, 0.52, 0.24, 1), null, 0, 12, null, 0, Vector2.ZERO, Vector4(20, 10, 20, 10))
	var primary_pressed := _sb(Color(0.06, 0.42, 0.21, 1), null, 0, 12, null, 0, Vector2.ZERO, Vector4(20, 10, 20, 10))
	var ghost := _sb(Color(0, 0, 0, 0), null, 0, 12, null, 0, Vector2.ZERO, Vector4(14, 8, 14, 8))
	var chip := _sb(Color(0.086, 0.639, 0.29, 1), null, 0, 20, null, 0, Vector2.ZERO, Vector4(14, 4, 14, 4))

	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Card", card)
	theme.set_type_variation("Card", "PanelContainer")
	theme.set_stylebox("panel", "Toast", toast)
	theme.set_type_variation("Toast", "PanelContainer")
	theme.set_stylebox("panel", "Chip", chip)
	theme.set_type_variation("Chip", "PanelContainer")

	theme.set_stylebox("normal", "Button", btn)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_font("font", "Button", font)
	theme.set_font_size("font_size", "Button", 15)
	theme.set_color("font_color", "Button", Color(0.15, 0.18, 0.26, 1))
	theme.set_color("font_hover_color", "Button", Color(0.08, 0.1, 0.18, 1))
	theme.set_color("font_pressed_color", "Button", Color(0.05, 0.07, 0.13, 1))
	theme.set_constant("h_separation", "Button", 8)

	theme.set_stylebox("normal", "PrimaryButton", primary)
	theme.set_stylebox("hover", "PrimaryButton", primary_hover)
	theme.set_stylebox("pressed", "PrimaryButton", primary_pressed)
	theme.set_font("font", "PrimaryButton", font_bold)
	theme.set_font_size("font_size", "PrimaryButton", 16)
	theme.set_color("font_color", "PrimaryButton", Color(1, 1, 1, 1))
	theme.set_color("font_hover_color", "PrimaryButton", Color(1, 1, 1, 1))
	theme.set_color("font_pressed_color", "PrimaryButton", Color(0.92, 0.98, 0.94, 1))
	theme.set_type_variation("PrimaryButton", "Button")

	theme.set_stylebox("normal", "GhostButton", ghost)
	theme.set_stylebox("hover", "GhostButton", btn_hover)
	theme.set_stylebox("pressed", "GhostButton", btn_pressed)
	theme.set_color("font_color", "GhostButton", Color(0.4, 0.44, 0.52, 1))
	theme.set_color("font_hover_color", "GhostButton", Color(0.15, 0.18, 0.26, 1))
	theme.set_type_variation("GhostButton", "Button")

	var err := ResourceSaver.save(theme, "res://ui/theme.tres")
	print("save result: ", err)
	quit(err)

func _sb(bg: Color, border: Variant, border_width: int, radius: int, shadow: Variant, shadow_size: int, shadow_offset: Vector2, margins: Vector4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	if border != null:
		sb.border_width_left = border_width
		sb.border_width_top = border_width
		sb.border_width_right = border_width
		sb.border_width_bottom = border_width
		sb.border_color = border
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	if shadow != null:
		sb.shadow_color = shadow
		sb.shadow_size = shadow_size
		sb.shadow_offset = shadow_offset
	sb.content_margin_left = margins.x
	sb.content_margin_top = margins.y
	sb.content_margin_right = margins.z
	sb.content_margin_bottom = margins.w
	return sb
