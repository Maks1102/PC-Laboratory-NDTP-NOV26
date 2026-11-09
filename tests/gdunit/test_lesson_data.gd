extends GdUnitTestSuite
## Валидация текстов и структуры ресурсов урока (gdUnit4):
## «корректность текстов подсказок» из п.8 TODO.

const PART_IDS := ["mobo", "cpu", "cooler", "ram", "ssd", "psu", "gpu", "case"]

func test_sequence_has_eight_steps_in_web_order() -> void:
	var seq: LessonSequence = load("res://resources/lesson_sequence.tres")
	assert_object(seq).is_not_null()
	assert_int(seq.steps.size()).is_equal(8)
	for i in seq.steps.size():
		assert_str(seq.steps[i].id).is_equal(GameState.STEP_IDS[i])

func test_every_step_has_title_task_and_hint() -> void:
	var seq: LessonSequence = load("res://resources/lesson_sequence.tres")
	for step in seq.steps:
		assert_str(step.title).is_not_empty()
		assert_str(step.task).is_not_empty()
		assert_str(step.extra_hint).is_not_empty()
		assert_bool(step.focus.length() > 0.01).is_true()   # камера смотрит на деталь

func test_install_steps_have_place_task_and_error_texts() -> void:
	var seq: LessonSequence = load("res://resources/lesson_sequence.tres")
	for step in seq.steps:
		if step.kind == LessonStep.Kind.INSTALL:
			assert_str(step.place_task).is_not_empty()
			assert_str(step.wrong_part).is_not_empty()
			assert_str(step.wrong_slot).is_not_empty()
			assert_str(step.slot_id).is_not_empty()

func test_explore_step_has_no_slot() -> void:
	var seq: LessonSequence = load("res://resources/lesson_sequence.tres")
	for step in seq.steps:
		if step.kind == LessonStep.Kind.EXPLORE:
			assert_str(step.slot_id).is_empty()

func test_slot_ids_are_known_and_parts_exist() -> void:
	var defs: SlotDefs = load("res://resources/slot_defs.tres")
	assert_object(defs).is_not_null()
	assert_int(defs.slot_to_part.size()).is_equal(6)
	for slot_id in defs.slot_to_part.keys():
		assert_str(slot_id).starts_with("slot-")
		assert_bool(PART_IDS.has(defs.slot_to_part[slot_id])).is_true()
		assert_bool(defs.slot_labels.has(slot_id)).is_true()

func test_step_part_and_slot_references_are_valid() -> void:
	var seq: LessonSequence = load("res://resources/lesson_sequence.tres")
	var defs: SlotDefs = load("res://resources/slot_defs.tres")
	for step in seq.steps:
		assert_bool(PART_IDS.has(step.part_id)).is_true()
		if not step.slot_id.is_empty():
			assert_bool(defs.slot_to_part.has(step.slot_id)).is_true()

func test_part_infos_are_complete() -> void:
	for id in PART_IDS:
		var info: PartInfo = load("res://resources/parts/%s.tres" % id)
		assert_object(info).is_not_null()
		assert_str(info.name).is_not_empty()
		assert_str(info.short_name).is_not_empty()
		assert_str(info.tagline).is_not_empty()
		assert_str(info.description).is_not_empty()
		assert_str(info.why).is_not_empty()
		assert_str(info.fact).is_not_empty()
		assert_str(info.one_liner).is_not_empty()
		assert_str(info.color).starts_with("#")
		assert_int(info.specs.size()).is_greater_equal(1)

func test_cooler_step_clicks_cpu_as_alt_target() -> void:
	var seq: LessonSequence = load("res://resources/lesson_sequence.tres")
	for step in seq.steps:
		if step.id == "step-cooler":
			assert_array(step.alt_targets).contains("cpu")
