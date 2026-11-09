extends GdUnitTestSuite
## Юнит-тесты стейт-машины урока (gdUnit4): фазы, шаги, установка, сброс.
## Запуск: godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/gdunit --ignoreHeadlessMode

var _rejected: Array[String] = []

func _on_rejected(reason: String) -> void:
	_rejected.append(reason)

func before_test() -> void:
	GameState.reset()
	_rejected.clear()
	if not EventBus.part_rejected.is_connected(_on_rejected):
		EventBus.part_rejected.connect(_on_rejected)

func test_start_opens_first_explore_step() -> void:
	GameState.start()
	assert_str(GameState.step().id).is_equal("step-mobo")
	assert_int(GameState.phase).is_equal(GameState.Phase.EXPLORE)
	assert_bool(GameState.finished).is_false()

func test_wrong_part_keeps_phase_and_reports() -> void:
	GameState.start()
	GameState.pick_part("mobo")       # осмотр → карточка
	assert_int(GameState.phase).is_equal(GameState.Phase.CARD)
	GameState.next_step()             # шаг 2: процессор, выбор детали
	GameState.pick_part("gpu")        # не та деталь
	assert_int(GameState.phase).is_equal(GameState.Phase.SELECT)
	assert_array(_rejected).is_not_empty()
	assert_str(_rejected[0]).is_not_empty()

func test_full_install_flow_places_part_and_advances() -> void:
	GameState.start()
	GameState.pick_part("mobo")
	GameState.next_step()             # step-cpu, SELECT
	GameState.pick_part("cpu")
	assert_int(GameState.phase).is_equal(GameState.Phase.PLACE)
	GameState.pick_slot("slot-cpu")
	assert_int(GameState.phase).is_equal(GameState.Phase.CARD)
	assert_array(GameState.installed).contains("cpu")
	GameState.next_step()             # step-cooler
	assert_str(GameState.step().id).is_equal("step-cooler")

func test_wrong_slot_keeps_place_phase() -> void:
	GameState.start()
	GameState.pick_part("mobo")
	GameState.next_step()
	GameState.pick_part("cpu")
	GameState.pick_slot("slot-ram")   # не тот слот
	# pick_slot с неверным слотом: фаза PLACE не должна дать установку
	assert_array(GameState.installed).not_contains("cpu")

func test_all_eight_steps_to_done() -> void:
	GameState.start()
	while not GameState.finished:
		var step: LessonStep = GameState.step()
		if step.kind == LessonStep.Kind.EXPLORE:
			GameState.pick_part(step.part_id)
		else:
			GameState.pick_part(step.part_id)
			GameState.pick_slot(step.slot_id)
		GameState.next_step()
	assert_int(GameState.installed.size()).is_equal(7)
	assert_int(GameState.step_enum()).is_equal(GameState.Step.DONE)

func test_reset_restores_initial_state() -> void:
	GameState.start()
	GameState.pick_part("mobo")
	GameState.next_step()
	GameState.reset()
	assert_int(GameState.step_idx).is_equal(0)
	assert_str(GameState.step().id).is_equal("step-mobo")
	assert_int(GameState.installed.size()).is_equal(0)
	assert_bool(GameState.finished).is_false()

func test_highlight_targets_follow_phase() -> void:
	GameState.start()
	assert_array(GameState.highlight_targets()["parts"]).contains("mobo")
	GameState.pick_part("mobo")       # → CARD
	GameState.next_step()             # SELECT по cpu
	assert_array(GameState.highlight_targets()["parts"]).contains("cpu")
	GameState.pick_part("cpu")        # → PLACE
	assert_array(GameState.highlight_targets()["slots"]).contains("slot-cpu")
