extends Control
## Экран «Сборка завершена» (п.5 TODO, P1): появляется после последнего шага,
## кнопка «Включить компьютер» отправляет EventBus.power_on и открывает POST.

signal power_pressed
signal reset_pressed

@onready var _power: Button = $Center/Panel/Margin/VBox/PowerButton
@onready var _reset: Button = $Center/Panel/Margin/VBox/ResetButton

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	# Зелёная «круглая» галка.
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.086, 0.639, 0.29, 1)
	sb.corner_radius_top_left = 48
	sb.corner_radius_top_right = 48
	sb.corner_radius_bottom_left = 48
	sb.corner_radius_bottom_right = 48
	sb.shadow_color = Color(0.05, 0.35, 0.16, 0.5)
	sb.shadow_size = 12
	var circle: Panel = $Center/Panel/Margin/VBox/CheckCircle
	circle.add_theme_stylebox_override("panel", sb)
	_power.pressed.connect(func() -> void:
		visible = false
		power_pressed.emit())
	_reset.pressed.connect(func() -> void:
		visible = false
		reset_pressed.emit())

func show_screen() -> void:
	visible = true
