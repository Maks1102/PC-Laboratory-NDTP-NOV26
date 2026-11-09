extends Control
## Диалог «Библиотека» (п.5/задел GameState.open_library): все 8 деталей,
## клик по кнопке открывает карточку знаний.

const PART_IDS := ["mobo", "cpu", "cooler", "ram", "ssd", "psu", "gpu", "case"]

@onready var _grid: GridContainer = $Center/Panel/Margin/VBox/Grid

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	$Center/Panel/Margin/VBox/Header/CloseButton.pressed.connect(func() -> void: visible = false)
	EventBus.library_requested.connect(func() -> void: visible = true)
	for id in PART_IDS:
		var info: PartInfo = load("res://resources/parts/%s.tres" % id)
		if info == null:
			continue
		var button := Button.new()
		button.text = info.short_name
		button.custom_minimum_size = Vector2(120, 72)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func() -> void:
			visible = false
			_open_card(id))
		_grid.add_child(button)

func _open_card(part_id: String) -> void:
	GameState.show_info(part_id)
