extends Node3D
## End-to-end тест UI-потока M2: приветствие → 8 шагов (с нажатием кнопок UI,
## включая «Дальше →» на карточке) → экран «Сборка завершена» → POST →
## поздравление → «Собрать заново». Проверяет видимость панелей и сигналы.
## Запуск: godot --path . res://tests/test_ui_flow.tscn   (нужен дисплей, но работает и headless)
## Вывод: TEST_UI_FLOW: PASS / FAIL (код выхода 0/1)

var _main: Node3D
var _frames := 0
var _stage := 0
var _failures: Array[String] = []

func _check(condition: bool, what: String) -> void:
	if condition:
		print("  ok: ", what)
	else:
		printerr("  FAIL: ", what)
		_failures.append(what)

func _ready() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)

func _ui() -> Control:
	return _main.get_node("UILayer/UI")

func _process(_delta: float) -> void:
	_frames += 1
	match _stage:
		0:
			if _frames > 10:
				_check(_ui().get_node("Dialog").visible, "приветствие видно при старте")
				_press_dialog_button("start")
				_stage = 1
		1:
			if _frames > 20:
				_check(not _ui().get_node("Dialog").visible, "приветствие закрылось кнопкой «Начать сборку»")
				_stage = 2
		2:
			if _frames > 30:
				_run_through_steps()
				_stage = 3
		3:
			# Ждём таймер 0.8 с из ui_root (кадровый headless быстрее 60 fps — ждём по условию).
			var completion := _ui().get_node("CompletionScreen")
			if completion.visible:
				_check(true, "экран «Сборка завершена» показан")
				var power: Button = _ui().get_node("CompletionScreen/Center/Panel/Margin/VBox/PowerButton")
				power.pressed.emit()
				_stage = 4
				_frames = 0
			elif _frames > 900:
				_check(false, "экран «Сборка завершена» показан (таймаут)")
				_main.get_node("UILayer/UI/CompletionScreen").visible = true
				_stage = 7
		4:
			if _frames > 5:
				_check(_ui().get_node("PostOverlay").visible, "POST-оверлей показан после «Включить компьютер»")
				_stage = 5
				_frames = 0
		5:
			# POST длится ~3.5 с; ждём по условию (поздравление видимо), а не по кадрам.
			var dlg := _ui().get_node("Dialog")
			if dlg.visible:
				var title: Label = dlg.get_node("Center/Panel/Margin/VBox/TitleLabel")
				if title.text.contains(tr("Поздравляем")):
					_check(true, "финальное поздравление показано")
					_press_dialog_button("again")
					_stage = 6
					_frames = 0
			elif _frames > 9000:
				_check(false, "поздравление появилось (таймаут POST)")
				_stage = 7
		6:
			if _frames > 20:
				_check(GameState.step_idx == 0 and not GameState.finished, "«Собрать заново» сбросила урок")
				_check(is_equal_approx(_main._fan_target, 0.0), "вентиляторы остановлены после reset")
				_stage = 7
		7:
			if _frames > 30:
				if _failures.is_empty():
					print("TEST_UI_FLOW: PASS")
					get_tree().quit(0)
				else:
					for f in _failures:
						printerr("  - ", f)
					print("TEST_UI_FLOW: FAIL (%d)" % _failures.size())
					get_tree().quit(1)

## Прогоняет все 8 шагов так же, как игрок: клик по детали, по слоту, «Дальше →».
func _run_through_steps() -> void:
	for i in 8:
		var step: LessonStep = GameState.step()
		if step.kind == LessonStep.Kind.EXPLORE:
			GameState.pick_part(step.part_id)
			_check(GameState.phase == GameState.Phase.CARD, "шаг %d: карточка открыта после клика" % (i + 1))
		else:
			GameState.pick_part(step.part_id)
			_check(GameState.phase == GameState.Phase.PLACE, "шаг %d: фаза PLACE после выбора детали" % (i + 1))
			GameState.pick_slot(step.slot_id)
			_check(GameState.phase == GameState.Phase.CARD, "шаг %d: установлено, фаза CARD" % (i + 1))
			_check(GameState.installed.has(step.part_id), "шаг %d: деталь %s в installed" % [i + 1, step.part_id])
		# Кнопка «Дальше →» на карточке — как нажал бы игрок.
		var card: PanelContainer = _ui().get_node("PartCard")
		_check(card.visible, "шаг %d: карточка видна" % (i + 1))
		var action: Button = card.get_node("Margin/VBox/ActionButton")
		action.pressed.emit()
		_check(GameState.step_idx == i + 1 or GameState.finished, "шаг %d: перешли дальше" % (i + 1))
	_check(GameState.finished, "урок завершён после 8 шагов")
	_check(is_equal_approx(_main._fan_target, 0.0), "до включения вентиляторы не крутятся")

func _press_dialog_button(id: String) -> void:
	var row: HBoxContainer = _ui().get_node("Dialog/Center/Panel/Margin/VBox/ButtonsRow")
	for button in row.get_children():
		if button is Button and _button_id(button) == id:
			button.pressed.emit()
			return
	printerr("  FAIL: кнопка «%s» не найдена в диалоге" % id)
	_failures.append("dialog button %s missing" % id)

## id кнопки хранится в метаданных, созданных dialog.gd.
func _button_id(button: Button) -> String:
	var meta: Variant = button.get_meta("dialog_id", "")
	return str(meta)