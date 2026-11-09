extends Node3D
## Снимки экранов M2 для визуальной проверки: карточка, completion, POST, поздравление.
var _main: Node3D
var _frames := 0
var _stage := 0

func _ready() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)

func _ui() -> Control:
	return _main.get_node("UILayer/UI")

func _save(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://tests/screenshots/%s.png" % name)
	print("SHOT ", name)

func _process(_delta: float) -> void:
	_frames += 1
	var ui := _ui()
	match _stage:
		0:
			if _frames > 10:
				# Закрываем приветствие и ставим шаг 1 (осмотр МОБО) → карточка видна.
				var start: Button = _find_dialog_button("start")
				start.pressed.emit()
				GameState.pick_part("mobo")
				_stage = 1
				_frames = 0
		1:
			if _frames > 15:
				_save("ui-card-mobo")
				var card: PanelContainer = _ui().get_node("PartCard")
				var action: Button = card.get_node("Margin/VBox/ActionButton")
				action.pressed.emit()  # шаг 1 пройден → шаг 2 (CPU, фаза выбора)
				_stage = 8
				_frames = 0
		8:
			if _frames > 5:
				GameState.pick_part("gpu")  # не та деталь → тост ошибки wrong_part
				_stage = 9
				_frames = 0
		9:
			if _frames > 10:
				_save("ui-toast")
				_stage = 2
				_frames = 0
		2:
			# Прогоняем 8 шагов и жмём «Дальше» на карточке.
			_run_all()
			_stage = 3
			_frames = 0
		3:
			if _ui().get_node("CompletionScreen").visible:
				_save("ui-completion")
				_stage = 4
				_frames = 0
		4:
			if _frames > 5:
				_ui().get_node("CompletionScreen/Center/Panel/Margin/VBox/PowerButton").pressed.emit()
				_stage = 5
				_frames = 0
		5:
			if _frames > 80:
				_save("ui-post")
				_stage = 6
				_frames = 0
		6:
			if _ui().get_node("Dialog").visible:
				_save("ui-congrats")
				get_tree().quit(0)
			elif _frames > 1500:
				print("timeout waiting congrats")
				get_tree().quit(1)

func _run_all() -> void:
	# Доигрываем оставшиеся шаги от текущего до финала.
	while not GameState.finished:
		var step: LessonStep = GameState.step()
		if step.kind == LessonStep.Kind.EXPLORE:
			GameState.pick_part(step.part_id)
		else:
			GameState.pick_part(step.part_id)
			GameState.pick_slot(step.slot_id)
		var card: PanelContainer = _ui().get_node("PartCard")
		var action: Button = card.get_node("Margin/VBox/ActionButton")
		action.pressed.emit()

func _find_dialog_button(id: String) -> Button:
	var row: HBoxContainer = _ui().get_node("Dialog/Center/Panel/Margin/VBox/ButtonsRow")
	for button in row.get_children():
		if button is Button and str(button.get_meta("dialog_id", "")) == id:
			return button
	return null
