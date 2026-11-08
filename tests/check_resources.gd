extends SceneTree
## Проверка всех .tres-ресурсов M0: 8 шагов урока, 8 карточек деталей, слоты.
## Запуск: Godot --headless --path . --script res://tests/check_resources.gd

const STEP_IDS: Array[String] = [
	"step-mobo", "step-cpu", "step-cooler", "step-ram",
	"step-ssd", "step-mobo-case", "step-psu", "step-gpu",
]
const PART_KINDS: Array[String] = ["mobo", "cpu", "cooler", "ram", "ssd", "psu", "gpu", "case"]
const SLOT_IDS: Array[String] = ["slot-cpu", "slot-ram", "slot-m2", "slot-pcie", "slot-psu", "slot-case"]

var fails: Array[String] = []

func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)

func _init() -> void:
	_check_slot_defs()
	_check_steps()
	_check_sequence()
	_check_parts()

	if fails.is_empty():
		print("CHECK_RESOURCES: PASS (8 шагов + 8 карточек + 6 слотов)")
		quit(0)
	else:
		for f in fails:
			printerr("FAIL: " + f)
		print("CHECK_RESOURCES: FAIL (%d)" % fails.size())
		quit(1)

func _check_slot_defs() -> void:
	var defs: SlotDefs = load("res://resources/slot_defs.tres")
	_check(defs != null, "slot_defs.tres загружается")
	if defs == null:
		return
	_check(defs.slot_labels.size() == 6, "slot_labels: 6 записей")
	_check(defs.slot_to_part.size() == 6, "slot_to_part: 6 записей")
	for slot_id in SLOT_IDS:
		_check(defs.slot_labels.has(slot_id), "нет подписи " + slot_id)
		_check(defs.slot_to_part.has(slot_id), "нет соответствия " + slot_id)

func _check_steps() -> void:
	for i in STEP_IDS.size():
		var id: String = STEP_IDS[i]
		var step: LessonStep = load("res://resources/lessons/%s.tres" % id)
		_check(step != null, "%s.tres загружается" % id)
		if step == null:
			continue
		_check(step.id == id, "%s: id совпадает с именем файла" % id)
		_check(not step.title.is_empty(), "%s: title не пустой" % id)
		_check(not step.task.is_empty(), "%s: task не пустой" % id)
		_check(not step.extra_hint.is_empty(), "%s: extra_hint не пустой" % id)
		_check(step.focus != Vector3.ZERO, "%s: focus задан" % id)
		if i == 0:
			_check(step.kind == LessonStep.Kind.EXPLORE, "%s: kind=EXPLORE" % id)
			_check(step.slot_id.is_empty(), "%s: у шага осмотра нет слота" % id)
		else:
			_check(step.kind == LessonStep.Kind.INSTALL, "%s: kind=INSTALL" % id)
			_check(not step.slot_id.is_empty(), "%s: slot_id задан" % id)
			_check(not step.place_task.is_empty(), "%s: place_task не пустой" % id)
			_check(not step.wrong_part.is_empty(), "%s: wrong_part не пустой" % id)
			_check(not step.wrong_slot.is_empty(), "%s: wrong_slot не пустой" % id)
	# Особые случаи из веб-версии.
	var cooler: LessonStep = load("res://resources/lessons/step-cooler.tres")
	_check(cooler.alt_targets.has("cpu"), "step-cooler: alt_targets содержит cpu (кулер ставится на процессор)")
	var mobo_case: LessonStep = load("res://resources/lessons/step-mobo-case.tres")
	_check(mobo_case.cam != Vector3.ZERO, "step-mobo-case: cam задан (работа с корпусом)")
	_check(mobo_case.part_id == "mobo", "step-mobo-case: part_id=mobo (переезд собранного узла)")

func _check_sequence() -> void:
	var seq: LessonSequence = load("res://resources/lesson_sequence.tres")
	_check(seq != null, "lesson_sequence.tres загружается")
	if seq == null:
		return
	_check(seq.steps.size() == 8, "sequence: 8 шагов")
	for i in mini(seq.steps.size(), STEP_IDS.size()):
		_check(seq.steps[i].id == STEP_IDS[i], "sequence[%d] == %s" % [i, STEP_IDS[i]])

func _check_parts() -> void:
	for kind in PART_KINDS:
		var part: PartInfo = load("res://resources/parts/%s.tres" % kind)
		_check(part != null, "parts/%s.tres загружается" % kind)
		if part == null:
			continue
		_check(part.kind == kind, "parts/%s: kind совпадает" % kind)
		_check(not part.name.is_empty(), "parts/%s: name не пустой" % kind)
		_check(not part.description.is_empty(), "parts/%s: description не пустой" % kind)
		_check(not part.fact.is_empty(), "parts/%s: fact не пустой" % kind)
		_check(part.specs.size() >= 3, "parts/%s: specs ≥ 3" % kind)
		_check(part.color.begins_with("#"), "parts/%s: color — HEX" % kind)
	# SLOT_TO_PART ссылается только на существующие детали.
	var defs: SlotDefs = load("res://resources/slot_defs.tres")
	if defs != null:
		for slot_id in defs.slot_to_part:
			var part_id: String = defs.slot_to_part[slot_id]
			_check(PART_KINDS.has(part_id), "slot_to_part[%s] → неизвестная деталь %s" % [slot_id, part_id])
