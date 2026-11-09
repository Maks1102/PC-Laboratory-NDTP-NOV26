extends PanelContainer
## Панель урока (п.5 TODO): номер шага, заголовок, текст задания
## с переключением task → place_task при взятии детали, точки прогресса,
## кнопки «Подсказка» / «Детали» / «Заново».

const STEP_COUNT := 8

var _dots: Array[Panel] = []

@onready var _badge: Label = $Margin/VBox/HeaderRow/StepBadge/BadgeLabel
@onready var _title: Label = $Margin/VBox/HeaderRow/TitleLabel
@onready var _task: Label = $Margin/VBox/TaskLabel
@onready var _hint_panel: PanelContainer = $Margin/VBox/HintPanel
@onready var _hint_label: Label = $Margin/VBox/HintPanel/HintLabel
@onready var _dots_row: HBoxContainer = $Margin/VBox/ProgressDots

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	_build_dots()
	$Margin/VBox/ButtonsRow/HintButton.pressed.connect(_on_hint)
	$Margin/VBox/ButtonsRow/LibraryButton.pressed.connect(GameState.open_library)
	$Margin/VBox/ButtonsRow/ResetButton.pressed.connect(GameState.reset)
	EventBus.step_changed.connect(func(_id: String) -> void: _refresh())
	EventBus.phase_changed.connect(func(_p: int) -> void: _refresh())
	_refresh()

func _build_dots() -> void:
	for i in STEP_COUNT:
		var dot := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8
		sb.corner_radius_bottom_right = 8
		sb.bg_color = Color(0.87, 0.85, 0.77, 1)
		sb.content_margin_left = 0
		sb.content_margin_top = 0
		sb.content_margin_right = 0
		sb.content_margin_bottom = 0
		dot.add_theme_stylebox_override("panel", sb)
		dot.custom_minimum_size = Vector2(16, 16)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots_row.add_child(dot)
		_dots.append(dot)

func _refresh() -> void:
	_hint_panel.visible = false
	if GameState.finished:
		_badge.text = tr("Финал")
		_title.text = tr("Сборка завершена")
		_task.text = tr("Ты собрал компьютер с нуля. Нажми «Включить компьютер» на финальном экране — и проверим результат.")
		_paint_dots(STEP_COUNT)
		return
	var step := GameState.step()
	var idx := GameState.step_idx
	_badge.text = tr("Шаг %d/%d") % [idx + 1, STEP_COUNT]
	_title.text = step.title
	match GameState.phase:
		GameState.Phase.PLACE:
			_task.text = step.place_task if not step.place_task.is_empty() else step.task
		GameState.Phase.CARD:
			_task.text = tr("Готово! Посмотри карточку и нажми «Дальше».")
		_:
			_task.text = step.task
	_paint_dots(idx + 1)

func _paint_dots(filled: int) -> void:
	filled = clampi(filled, 1, STEP_COUNT)
	for i in STEP_COUNT:
		var sb := _dots[i].get_theme_stylebox("panel") as StyleBoxFlat
		sb.bg_color = Color(0.086, 0.639, 0.29, 1) if i < filled else Color(0.87, 0.85, 0.77, 1)

func _on_hint() -> void:
	_hint_label.text = tr("Подсказка: ") + GameState.hint()
	_hint_panel.visible = not _hint_panel.visible
