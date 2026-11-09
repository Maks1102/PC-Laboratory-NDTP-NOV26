extends GdUnitTestSuite
## Юнит-тесты зон-подсказок (gdUnit4): скрытие после установки (п.5/6 TODO),
## отсутствие коллизии.

var _root: Node3D

func before_test() -> void:
	_root = Node3D.new()
	add_child(_root)

func after_test() -> void:
	_root.queue_free()

func test_hint_zone_is_visible_by_default() -> void:
	var zone := HintZone.new()
	zone.hide_after_part = "mobo"
	zone.box_size = Vector3(2, 2, 2)
	_root.add_child(zone)
	assert_bool(zone.visible).is_true()

func test_hint_zone_hides_after_matching_part_installed() -> void:
	var zone := HintZone.new()
	zone.hide_after_part = "mobo"
	zone.box_size = Vector3(2, 2, 2)
	_root.add_child(zone)
	EventBus.part_installed.emit("mobo")
	assert_bool(zone.visible).is_false()

func test_hint_zone_ignores_other_parts() -> void:
	var zone := HintZone.new()
	zone.hide_after_part = "psu"
	zone.box_size = Vector3(2, 2, 2)
	_root.add_child(zone)
	EventBus.part_installed.emit("mobo")
	assert_bool(zone.visible).is_true()
	EventBus.part_installed.emit("psu")
	assert_bool(zone.visible).is_false()

func test_hint_zone_has_no_collision() -> void:
	var zone := HintZone.new()
	_root.add_child(zone)
	assert_object(zone.find_child("CollisionShape3D", true, false)).is_null()
	for child in zone.get_children():
		assert_object(child as CollisionShape3D).is_null()

func test_hint_case_zone_appears_only_on_its_step() -> void:
	GameState.reset()
	var zone := HintZone.new()
	zone.show_on_steps = PackedStringArray(["step-mobo-case"])
	zone.hide_after_part = "mobo"
	_root.add_child(zone)
	assert_bool(zone.visible).is_false()  # шаг 1 (осмотр платы) — зоны нет
	# Проходим шаги 0–4.
	while GameState.step().id != "step-mobo-case":
		var step: LessonStep = GameState.step()
		if step.kind == LessonStep.Kind.EXPLORE:
			GameState.pick_part(step.part_id)
		else:
			GameState.pick_part(step.part_id)
			GameState.pick_slot(step.slot_id)
		GameState.next_step()
	assert_bool(zone.visible).is_true()  # шаг «плата в корпус» — зона показана
	GameState.pick_part("mobo")
	GameState.pick_slot("slot-case")     # плата установлена → зона скрывается
	assert_bool(zone.visible).is_false()
	GameState.reset()
	assert_bool(zone.visible).is_false()  # после «Собрать заново» снова на месте, но шаг 1 — скрыта


func test_hint_psu_zone_appears_only_on_psu_step() -> void:
	GameState.reset()
	var zone := HintZone.new()
	zone.show_on_steps = PackedStringArray(["step-psu"])
	zone.hide_after_part = "psu"
	_root.add_child(zone)
	assert_bool(zone.visible).is_false()
	while GameState.step().id != "step-psu":
		var step: LessonStep = GameState.step()
		if step.kind == LessonStep.Kind.EXPLORE:
			GameState.pick_part(step.part_id)
		else:
			GameState.pick_part(step.part_id)
			GameState.pick_slot(step.slot_id)
		GameState.next_step()
	assert_bool(zone.visible).is_true()
	GameState.pick_part("psu")
	GameState.pick_slot("slot-psu")
	assert_bool(zone.visible).is_false()
	GameState.reset()
