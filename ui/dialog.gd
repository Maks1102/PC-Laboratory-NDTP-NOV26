extends Control
## Универсальный диалог (п.5 TODO): приветствие, финал-поздравление, библиотека.
## Кнопки задаются списком словарей {id, text, primary}; сигнал button_pressed(id).

signal button_pressed(id: String)

@onready var _dim: ColorRect = $Dim
@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var _body: Label = $Center/Panel/Margin/VBox/BodyLabel
@onready var _buttons: HBoxContainer = $Center/Panel/Margin/VBox/ButtonsRow

func _ready() -> void:
	theme = load("res://ui/theme.tres")

## Показать диалог. buttons: Array[{id: String, text: String, primary: bool}].
func show_dialog(title: String, body: String, buttons: Array) -> void:
	_title.text = title
	_body.text = body
	for child in _buttons.get_children():
		child.queue_free()
	for spec in buttons:
		var button := Button.new()
		button.text = str(spec.get("text", "OK"))
		if spec.get("primary", false):
			button.theme_type_variation = "PrimaryButton"
		var id := str(spec.get("id", "ok"))
		button.set_meta("dialog_id", id)
		button.pressed.connect(func() -> void:
			visible = false
			button_pressed.emit(id))
		_buttons.add_child(button)
	visible = true

func hide_dialog() -> void:
	visible = false
