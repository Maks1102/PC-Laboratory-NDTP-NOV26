extends Node
## Тест стейт-машины: все 8 шагов подряд, ошибки, перетаскивание, reset.
## Запуск (нормальный режим, автолоады доступны):
##   Godot --headless --path . res://tests/test_state_machine.tscn
## Код возврата 0 — PASS, 1 — FAIL.

var fails: Array[String] = []
var installed_events: Array[String] = []
var rejected_events: Array[String] = []
var step_events: Array[String] = []
var completed := false

func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)

func _ready() -> void:
	EventBus.part_installed.connect(func(id: String) -> void: installed_events.append(id))
	EventBus.part_rejected.connect(func(reason: String) -> void: rejected_events.append(reason))
	EventBus.step_changed.connect(func(id: String) -> void: step_events.append(id))
	EventBus.assembly_completed.connect(func() -> void: completed = true)

	_test_initial_state()
	_test_full_walkthrough()
	_test_wrong_part_and_slot()
	_test_drag_flow()
	_test_reset()

	if fails.is_empty():
		print("TEST_STATE_MACHINE: PASS")
		get_tree().quit(0)
	else:
		for f in fails:
			printerr("FAIL: " + f)
		print("TEST_STATE_MACHINE: FAIL (%d)" % fails.size())
		get_tree().quit(1)

func _test_initial_state() -> void:
	_check(GameState.started == false, "изначально started=false")
	_check(GameState.step_idx == 0, "изначально шаг 0")
	_check(GameState.step().id == "step-mobo", "шаг 0 — step-mobo, получено " + GameState.step().id)
	_check(GameState.sequence.steps.size() == 8, "в последовательности 8 шагов")
	_check(GameState.step_enum() == GameState.Step.MOBO, "step_enum() == MOBO")

func _test_full_walkthrough() -> void:
	GameState.start()
	_check(GameState.started, "start() выставил started")
	_check(GameState.phase == GameState.Phase.EXPLORE, "после start фаза EXPLORE")
	_check(GameState.highlight_targets()["parts"] == ["mobo"], "на шаге осмотра подсвечена mobo")

	# Шаг 0: осмотр — клик по цели открывает карточку и переводит в CARD.
	GameState.pick_part("mobo")
	_check(GameState.phase == GameState.Phase.CARD, "после клика по цели фаза CARD")
	_check(GameState.opened.has("mobo"), "mobo добавлена в opened")
	GameState.next_step()

	# Шаги 1–7: install-шаги — select → place → install.
	var expected := ["cpu", "cooler", "ram", "ssd", "mobo", "psu", "gpu"]
	for part_id in expected:
		var step_id: String = GameState.step().id
		_check(GameState.phase == GameState.Phase.SELECT, "%s: фаза SELECT после перехода" % step_id)
		_check(GameState.grabbable_part() == part_id, "%s: grabbable_part == %s" % [step_id, part_id])
		GameState.pick_part(part_id)  # правильная деталь → PLACE
		_check(GameState.phase == GameState.Phase.PLACE, "%s: фаза PLACE после выбора детали" % step_id)
		_check(GameState.selected == part_id, "%s: selected == %s" % [step_id, part_id])
		GameState.pick_slot(GameState.step().slot_id)  # правильный слот → install
		_check(GameState.phase == GameState.Phase.CARD, "%s: фаза CARD после установки" % step_id)
		_check(GameState.installed.has(part_id), "%s: %s в installed" % [step_id, part_id])
		GameState.next_step()

	_check(GameState.finished, "после последнего шага finished=true")
	_check(completed, "сигнал assembly_completed излучён")
	_check(GameState.step_enum() == GameState.Step.DONE, "step_enum() == DONE")
	_check(installed_events.size() == 7, "part_installed ×7, получено %d" % installed_events.size())
	_check(step_events.size() == 8, "step_changed ×8, получено %d" % step_events.size())
	_check(GameState.installed.size() == 7, "installed.size() == 7")

func _test_wrong_part_and_slot() -> void:
	GameState.reset()
	_check(GameState.finished == false, "reset сбросил finished")
	_check(GameState.installed.is_empty(), "reset очистил installed")
	_check(GameState.step_idx == 0, "reset вернул шаг 0")
	GameState.next_step()  # → step-cpu

	var rejected_before := rejected_events.size()
	GameState.pick_part("gpu")  # не та деталь
	_check(rejected_events.size() == rejected_before + 1, "wrong part → part_rejected")
	_check(GameState.phase == GameState.Phase.SELECT, "ошибка не сменила фазу SELECT")
	GameState.pick_part("cpu")
	GameState.pick_slot("slot-ram")  # не тот слот
	_check(rejected_events.size() == rejected_before + 2, "wrong slot → part_rejected")
	_check(GameState.phase == GameState.Phase.PLACE, "после ошибки слота фаза осталась PLACE")
	_check(not GameState.installed.has("cpu"), "cpu не установилась не в тот слот")

func _test_drag_flow() -> void:
	GameState.reset()
	GameState.next_step()  # step-cpu
	GameState.drag_start("cpu")
	_check(GameState.is_dragging, "drag_start выставил is_dragging")
	_check(GameState.phase == GameState.Phase.PLACE, "drag_start → фаза PLACE")
	GameState.drag_cancelled()
	_check(GameState.is_dragging == false, "drag_cancelled снял is_dragging")
	_check(GameState.phase == GameState.Phase.SELECT, "после отмены фаза SELECT")
	GameState.drag_start("cpu")
	_check(GameState.is_dragging, "повторный drag_start работает")
	GameState.drag_placed("cpu")
	_check(GameState.is_dragging == false, "drag_placed снял is_dragging")
	_check(GameState.installed.has("cpu"), "drag_placed установил cpu")
	# Защита busy: второй drag при busy=true игнорируется.
	GameState.set_busy(true)
	var sel_before: String = GameState.selected
	GameState.drag_start("ram")
	_check(GameState.selected == sel_before, "drag_start проигнорирован при busy")
	GameState.set_busy(false)

func _test_reset() -> void:
	GameState.reset()
	_check(GameState.started, "reset оставил started=true (урок продолжается)")
	_check(GameState.step_idx == 0 and GameState.phase == GameState.Phase.EXPLORE, "reset → шаг 0, EXPLORE")
	_check(GameState.opened.is_empty() and GameState.installed.is_empty(), "reset очистил opened/installed")
	_check(GameState.hint() is String and not GameState.hint().is_empty(), "hint() возвращает текст подсказки")
