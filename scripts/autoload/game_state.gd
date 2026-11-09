extends Node
## РђРІС‚РѕР»РѕР°Рґ GameState вЂ” СЃРѕСЃС‚РѕСЏРЅРёРµ СѓСЂРѕРєР° Рё СЃС‚РµР№С‚-РјР°С€РёРЅР°.
## РџСЂСЏРјРѕР№ РїРѕСЂС‚ Р»РѕРіРёРєРё РёР· src/components/simulator/simulator.tsx:
## С„Р°Р·С‹ explore в†’ select в†’ place в†’ card, 8 С€Р°РіРѕРІ, Р·Р°С‰РёС‚Р° busy (6 СЃ).

enum Phase { EXPLORE, SELECT, PLACE, CARD }

## РЁР°РіРё 0вЂ“7 + DONE. ID вЂ” РєР°Рє РІ РІРµР±-РІРµСЂСЃРёРё ("step-mobo", вЂ¦).
enum Step { MOBO, CPU, COOLER, RAM, SSD, MOBO_TO_CASE, PSU_TO_CASE, GPU, DONE }

const STEP_IDS: Array[String] = [
	"step-mobo", "step-cpu", "step-cooler", "step-ram",
	"step-ssd", "step-mobo-case", "step-psu", "step-gpu",
]

## РўР°Р№РјР°СѓС‚ busy: РµСЃР»Рё Р°РЅРёРјР°С†РёСЏ В«Р·Р°РІРёСЃР»Р°В» вЂ” РїСЂРёРЅСѓРґРёС‚РµР»СЊРЅС‹Р№ СЃР±СЂРѕСЃ (РІ РІРµР±Рµ 6 СЃ).
const BUSY_TIMEOUT_SEC := 6.0

var sequence: LessonSequence
var slot_defs: SlotDefs
var started := false
var finished := false
var step_idx := 0
var phase: Phase = Phase.EXPLORE
var selected := ""
var installed: Array[String] = []
var opened: Array[String] = []
var info_part := ""
var busy := false
## Р¤Р»Р°Рі РїРµСЂРµС‚Р°СЃРєРёРІР°РЅРёСЏ: РєР°РјРµСЂР° РїРѕР»РЅРѕСЃС‚СЊСЋ РёРіРЅРѕСЂРёСЂСѓРµС‚ РІРІРѕРґ, РїРѕРєР° true (Рї.3 TODO).
var is_dragging := false

var _busy_timer: Timer
## Р’СЂРµРјСЏ СЃС‚Р°СЂС‚Р° СѓСЂРѕРєР° (РјСЃРµРє РћРЎ) вЂ” РґР»СЏ С„РёРЅР°Р»СЊРЅРѕРіРѕ СЌРєСЂР°РЅР° В«РІСЂРµРјСЏ СЃР±РѕСЂРєРёВ».
var started_at := 0

func _ready() -> void:
	sequence = load("res://resources/lesson_sequence.tres")
	assert(sequence != null and sequence.steps.size() == 8, "lesson_sequence.tres: РѕР¶РёРґР°Р»РѕСЃСЊ 8 С€Р°РіРѕРІ")
	slot_defs = load("res://resources/slot_defs.tres")
	assert(slot_defs != null and slot_defs.slot_to_part.size() == 6, "slot_defs.tres: РѕР¶РёРґР°Р»РѕСЃСЊ 6 СЃР»РѕС‚РѕРІ")
	_busy_timer = Timer.new()
	_busy_timer.one_shot = true
	_busy_timer.wait_time = BUSY_TIMEOUT_SEC
	_busy_timer.timeout.connect(_on_busy_timeout)
	add_child(_busy_timer)

## РўРµРєСѓС‰РёР№ С€Р°Рі СѓСЂРѕРєР° ( LessonStep РёР· .tres ).
func step() -> LessonStep:
	return sequence.steps[step_idx]

## РРЅРґРµРєСЃ С€Р°РіР° в†’ enum Step; РїРѕСЃР»Рµ Р·Р°РІРµСЂС€РµРЅРёСЏ СЃР±РѕСЂРєРё вЂ” DONE.
func step_enum() -> Step:
	if finished or step_idx >= Step.DONE:
		return Step.DONE
	return step_idx as Step

func set_busy(value: bool) -> void:
	busy = value
	if value:
		_busy_timer.start()
	else:
		_busy_timer.stop()

func _on_busy_timeout() -> void:
	push_warning("[pc-laboratory] busy Р·Р°СЃС‚СЂСЏР» РІ true вЂ” РїСЂРёРЅСѓРґРёС‚РµР»СЊРЅС‹Р№ СЃР±СЂРѕСЃ")
	busy = false
	is_dragging = false
	selected = ""
	_set_phase(Phase.SELECT)

## Р•РґРёРЅР°СЏ С‚РѕС‡РєР° СЃРјРµРЅС‹ С„Р°Р·С‹: С„Р°Р·Р° + СЃРёРіРЅР°Р» РґР»СЏ UI.
func _set_phase(value: Phase) -> void:
	phase = value
	EventBus.phase_changed.emit(phase)

## РЎРµРєСѓРЅРґС‹ СЃ РЅР°С‡Р°Р»Р° СѓСЂРѕРєР° (РґР»СЏ С„РёРЅР°Р»СЊРЅРѕРіРѕ СЌРєСЂР°РЅР°).
func elapsed_seconds() -> float:
	if started_at <= 0:
		return 0.0
	return (Time.get_ticks_msec() - started_at) / 1000.0

# --- Р¶РёР·РЅРµРЅРЅС‹Р№ С†РёРєР» СѓСЂРѕРєР° ---

func start() -> void:
	started = true
	finished = false
	step_idx = 0
	started_at = Time.get_ticks_msec()
	_set_phase(Phase.EXPLORE)
	EventBus.step_changed.emit(step().id)

func next_step() -> void:
	if step_idx >= sequence.steps.size() - 1:
		# Р¤РёРЅР°Р»: РєР°РјРµСЂР° Рє СЃРѕР±СЂР°РЅРЅРѕРјСѓ РџРљ + Р°РЅРёРјР°С†РёСЏ РІРєР»СЋС‡РµРЅРёСЏ (РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚ СЃС†РµРЅР°).
		finished = true
		EventBus.assembly_completed.emit()
		return
	step_idx += 1
	selected = ""
	info_part = ""
	_set_phase(Phase.EXPLORE if step().kind == LessonStep.Kind.EXPLORE else Phase.SELECT)
	EventBus.step_changed.emit(step().id)

func reset() -> void:
	# РђРЅР°Р»РѕРі handleReset: РїРѕР»РЅС‹Р№ СЃР±СЂРѕСЃ, СѓСЂРѕРє РЅР°С‡РёРЅР°РµС‚СЃСЏ Р·Р°РЅРѕРІРѕ СЃ С€Р°РіР° 0.
	started = true
	finished = false
	step_idx = 0
	started_at = Time.get_ticks_msec()
	_set_phase(Phase.EXPLORE)
	selected = ""
	info_part = ""
	installed.clear()
	opened.clear()
	set_busy(false)
	is_dragging = false
	EventBus.power_off.emit()
	EventBus.step_changed.emit(step().id)

# --- РІС‹Р±РѕСЂ РґРµС‚Р°Р»РµР№ / СЃР»РѕС‚РѕРІ (РєР»РёРє) ---

func pick_part(part_id: String) -> void:
	if not started:
		return
	if finished:
		_open_info(part_id)
		return
	match phase:
		Phase.PLACE:
			if step().alt_targets.has(part_id):
				install_now()
			elif part_id == selected:
				EventBus.part_rejected.emit(tr("РўРµРїРµСЂСЊ РїРµСЂРµС‚Р°С‰Рё РґРµС‚Р°Р»СЊ Рє РїРѕРґСЃРІРµС‡РµРЅРЅРѕРјСѓ СЃР»РѕС‚Сѓ вЂ” РѕРЅР° РІСЃС‚Р°РЅРµС‚ РЅР° РјРµСЃС‚Рѕ СЃР°РјР°."))
			else:
				EventBus.part_rejected.emit(tr("РЎРЅР°С‡Р°Р»Р° СѓСЃС‚Р°РЅРѕРІРё РІС‹Р±СЂР°РЅРЅСѓСЋ РґРµС‚Р°Р»СЊ вЂ” РїРµСЂРµС‚Р°С‰Рё РµС‘ Рє РїРѕРґСЃРІРµС‡РµРЅРЅРѕРјСѓ СЃР»РѕС‚Сѓ."))
		Phase.SELECT:
			if part_id == step().part_id:
				selected = part_id
				_set_phase(Phase.PLACE)
			else:
				EventBus.part_rejected.emit(
					step().wrong_part if not step().wrong_part.is_empty()
					else tr("РЎРµР№С‡Р°СЃ РЅСѓР¶РЅР° РґСЂСѓРіР°СЏ РґРµС‚Р°Р»СЊ вЂ” РѕРЅР° РїРѕРґСЃРІРµС‡РµРЅР° РЅР° Р»РѕС‚РєРµ."))
		Phase.EXPLORE:
			_open_info(part_id)
			if part_id == step().part_id:
				_set_phase(Phase.CARD)
		_:
			_open_info(part_id)

func pick_slot(slot_id: String) -> void:
	if not started:
		return
	if phase == Phase.PLACE:
		if step().slot_id == slot_id:
			install_now()
		else:
			EventBus.part_rejected.emit(
				step().wrong_slot if not step().wrong_slot.is_empty()
				else tr("Р­С‚Рѕ РЅРµ С‚РѕС‚ СЃР»РѕС‚ вЂ” РѕСЂРёРµРЅС‚РёСЂСѓР№СЃСЏ РЅР° РїРѕРґСЃРІРµС‚РєСѓ."))
	elif phase == Phase.SELECT or phase == Phase.EXPLORE:
		EventBus.part_rejected.emit(tr("РЎРЅР°С‡Р°Р»Р° РІС‹Р±РµСЂРё РґРµС‚Р°Р»СЊ РЅР° Р»РѕС‚РєРµ вЂ” РёР»Рё СЃСЂР°Р·Сѓ РїРµСЂРµС‚Р°С‰Рё РµС‘ Рє СЃР»РѕС‚Сѓ."))
	else:
		_open_info(String(slot_defs.slot_to_part.get(slot_id, "")))

# --- СѓСЃС‚Р°РЅРѕРІРєР° ---

## РљРЅРѕРїРєР° В«РЈСЃС‚Р°РЅРѕРІРёС‚СЊВ» / РєР»РёРє РїРѕ Р°Р»СЊС‚РµСЂРЅР°С‚РёРІРЅРѕР№ С†РµР»Рё. РЎС†РµРЅР° Р°РЅРёРјРёСЂСѓРµС‚ Рё Р·РѕРІС‘С‚ complete_install().
func install_now() -> void:
	if busy or step().slot_id.is_empty() or step().kind != LessonStep.Kind.INSTALL:
		return
	set_busy(true)
	complete_install(step().part_id)

## РЁР°Рі 4-Р№ Р·Р°РІРµСЂС€С‘РЅ: РґРµС‚Р°Р»СЊ РЅР° РјРµСЃС‚Рµ (РІ РІРµР±Рµ вЂ” РєРѕР»Р±СЌРє scene.installPart).
func complete_install(part_id: String) -> void:
	set_busy(false)
	is_dragging = false
	if not installed.has(part_id):
		installed.append(part_id)
	selected = ""
	_set_phase(Phase.CARD)
	_open_info(part_id)
	EventBus.part_installed.emit(part_id)

# --- РїРµСЂРµС‚Р°СЃРєРёРІР°РЅРёРµ (drag & drop) ---

func drag_start(part_id: String) -> void:
	if busy:
		return
	set_busy(true)
	is_dragging = true
	selected = part_id
	_set_phase(Phase.PLACE)

func drag_placed(part_id: String) -> void:
	complete_install(part_id)

## РћС‚РїСѓСЃРєР°РЅРёРµ РґСЂР°РіР° РЅР°Рґ СЃР»РѕС‚РѕРј: РІР°Р»РёРґРЅС‹Р№ СЃР»РѕС‚ в†’ СѓСЃС‚Р°РЅРѕРІРєР° (СЌС‚Рѕ С‡Р°СЃС‚СЊ drag,
## busy РЅРµ РґРѕР»Р¶РµРЅ Р±Р»РѕРєРёСЂРѕРІР°С‚СЊ), РЅРµРІРµСЂРЅС‹Р№ в†’ РѕС€РёР±РєР° Рё РІРѕР·РІСЂР°С‚ РЅР° Р»РѕС‚РѕРє.
func drag_dropped(slot_id: String) -> void:
	if not started or finished or phase != Phase.PLACE:
		return
	if step().kind != LessonStep.Kind.INSTALL:
		return
	if step().slot_id == slot_id:
		complete_install(step().part_id)
		return
	# РќРµРІРµСЂРЅС‹Р№ СЃР»РѕС‚: РєР°Рє drag_cancelled, РЅРѕ СЃ С‚РµРєСЃС‚РѕРј wrong_slot.
	set_busy(false)
	is_dragging = false
	selected = ""
	_set_phase(Phase.SELECT)
	EventBus.part_rejected.emit(
		step().wrong_slot if not step().wrong_slot.is_empty()
		else tr("Р­С‚Рѕ РЅРµ С‚РѕС‚ СЃР»РѕС‚ вЂ” РѕСЂРёРµРЅС‚РёСЂСѓР№СЃСЏ РЅР° РїРѕРґСЃРІРµС‚РєСѓ."))

func drag_cancelled() -> void:
	set_busy(false)
	is_dragging = false
	selected = ""
	_set_phase(Phase.SELECT)
	EventBus.part_rejected.emit(tr("РњРёРјРѕ РїР°Р·Р° вЂ” РґРµС‚Р°Р»СЊ РІРµСЂРЅСѓР»Р°СЃСЊ РЅР° РјРµСЃС‚Рѕ. РўСЏРЅРё РµС‘ Рє РїРѕРґСЃРІРµС‡РµРЅРЅРѕРјСѓ СЃР»РѕС‚Сѓ."))

# --- РїСЂРѕС‡РµРµ ---

func hint() -> String:
	return step().extra_hint

func open_library() -> void:
	EventBus.library_requested.emit()

## Показать карточку знаний по id (используется библиотекой и сценой).
func show_info(part_id: String) -> void:
	_open_info(part_id)

func _open_info(part_id: String) -> void:
	if part_id.is_empty():
		return
	info_part = part_id
	if not opened.has(part_id):
		opened.append(part_id)
	EventBus.info_opened.emit(part_id)

## РџРѕРґСЃРІРµС‚РєР° РґР»СЏ СЃС†РµРЅС‹: РєР°РєСѓСЋ РґРµС‚Р°Р»СЊ Рё РєР°РєРѕР№ СЃР»РѕС‚ РїРѕРґСЃРІРµС‡РёРІР°С‚СЊ РІ С‚РµРєСѓС‰РµР№ С„Р°Р·Рµ.
func highlight_targets() -> Dictionary:
	if not started or finished:
		return {"parts": [], "slots": []}
	if phase == Phase.SELECT or phase == Phase.EXPLORE:
		return {"parts": [step().part_id], "slots": []}
	if phase == Phase.PLACE and not step().slot_id.is_empty():
		return {"parts": [], "slots": [step().slot_id]}
	return {"parts": [], "slots": []}

## РљР°РєСѓСЋ РґРµС‚Р°Р»СЊ РјРѕР¶РЅРѕ СЃС…РІР°С‚РёС‚СЊ РјС‹С€СЊСЋ (Р°РЅР°Р»РѕРі setDraggable РёР· РІРµР±-РІРµСЂСЃРёРё).
func grabbable_part() -> String:
	if started and not finished and step().kind == LessonStep.Kind.INSTALL \
			and (phase == Phase.SELECT or phase == Phase.PLACE):
		return step().part_id
	return ""
