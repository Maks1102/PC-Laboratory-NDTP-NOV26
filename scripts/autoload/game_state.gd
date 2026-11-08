extends Node
## Автолоад GameState — состояние урока и стейт-машина.
## Прямой порт логики из src/components/simulator/simulator.tsx:
## фазы explore → select → place → card, 8 шагов, защита busy (6 с).

enum Phase { EXPLORE, SELECT, PLACE, CARD }

## Шаги 0–7 + DONE. ID — как в веб-версии ("step-mobo", …).
enum Step { MOBO, CPU, COOLER, RAM, SSD, MOBO_TO_CASE, PSU_TO_CASE, GPU, DONE }

const STEP_IDS: Array[String] = [
	"step-mobo", "step-cpu", "step-cooler", "step-ram",
	"step-ssd", "step-mobo-case", "step-psu", "step-gpu",
]

## Таймаут busy: если анимация «зависла» — принудительный сброс (в вебе 6 с).
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
## Флаг перетаскивания: камера полностью игнорирует ввод, пока true (п.3 TODO).
var is_dragging := false

var _busy_timer: Timer

func _ready() -> void:
	sequence = load("res://resources/lesson_sequence.tres")
	assert(sequence != null and sequence.steps.size() == 8, "lesson_sequence.tres: ожидалось 8 шагов")
	slot_defs = load("res://resources/slot_defs.tres")
	assert(slot_defs != null and slot_defs.slot_to_part.size() == 6, "slot_defs.tres: ожидалось 6 слотов")
	_busy_timer = Timer.new()
	_busy_timer.one_shot = true
	_busy_timer.wait_time = BUSY_TIMEOUT_SEC
	_busy_timer.timeout.connect(_on_busy_timeout)
	add_child(_busy_timer)

## Текущий шаг урока ( LessonStep из .tres ).
func step() -> LessonStep:
	return sequence.steps[step_idx]

## Индекс шага → enum Step; после завершения сборки — DONE.
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
	push_warning("[pc-laboratory] busy застрял в true — принудительный сброс")
	busy = false
	is_dragging = false
	selected = ""

# --- жизненный цикл урока ---

func start() -> void:
	started = true
	finished = false
	step_idx = 0
	phase = Phase.EXPLORE
	EventBus.step_changed.emit(step().id)

func next_step() -> void:
	if step_idx >= sequence.steps.size() - 1:
		# Финал: камера к собранному ПК + анимация включения (обрабатывает сцена).
		finished = true
		EventBus.assembly_completed.emit()
		return
	step_idx += 1
	selected = ""
	info_part = ""
	phase = Phase.EXPLORE if step().kind == LessonStep.Kind.EXPLORE else Phase.SELECT
	EventBus.step_changed.emit(step().id)

func reset() -> void:
	# Аналог handleReset: полный сброс, урок начинается заново с шага 0.
	started = true
	finished = false
	step_idx = 0
	phase = Phase.EXPLORE
	selected = ""
	info_part = ""
	installed.clear()
	opened.clear()
	set_busy(false)
	is_dragging = false
	EventBus.step_changed.emit(step().id)

# --- выбор деталей / слотов (клик) ---

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
				EventBus.part_rejected.emit(tr("Теперь перетащи деталь к подсвеченному слоту — она встанет на место сама."))
			else:
				EventBus.part_rejected.emit(tr("Сначала установи выбранную деталь — перетащи её к подсвеченному слоту."))
		Phase.SELECT:
			if part_id == step().part_id:
				selected = part_id
				phase = Phase.PLACE
			else:
				EventBus.part_rejected.emit(
					step().wrong_part if not step().wrong_part.is_empty()
					else tr("Сейчас нужна другая деталь — она подсвечена на лотке."))
		Phase.EXPLORE:
			_open_info(part_id)
			if part_id == step().part_id:
				phase = Phase.CARD
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
				else tr("Это не тот слот — ориентируйся на подсветку."))
	elif phase == Phase.SELECT or phase == Phase.EXPLORE:
		EventBus.part_rejected.emit(tr("Сначала выбери деталь на лотке — или сразу перетащи её к слоту."))
	else:
		_open_info(String(slot_defs.slot_to_part.get(slot_id, "")))

# --- установка ---

## Кнопка «Установить» / клик по альтернативной цели. Сцена анимирует и зовёт complete_install().
func install_now() -> void:
	if busy or step().slot_id.is_empty() or step().kind != LessonStep.Kind.INSTALL:
		return
	set_busy(true)
	complete_install(step().part_id)

## Шаг 4-й завершён: деталь на месте (в вебе — колбэк scene.installPart).
func complete_install(part_id: String) -> void:
	set_busy(false)
	is_dragging = false
	if not installed.has(part_id):
		installed.append(part_id)
	selected = ""
	phase = Phase.CARD
	info_part = part_id
	EventBus.part_installed.emit(part_id)

# --- перетаскивание (drag & drop) ---

func drag_start(part_id: String) -> void:
	if busy:
		return
	set_busy(true)
	is_dragging = true
	selected = part_id
	phase = Phase.PLACE

func drag_placed(part_id: String) -> void:
	complete_install(part_id)

func drag_cancelled() -> void:
	set_busy(false)
	is_dragging = false
	selected = ""
	phase = Phase.SELECT
	EventBus.part_rejected.emit(tr("Мимо паза — деталь вернулась на место. Тяни её к подсвеченному слоту."))

# --- прочее ---

func hint() -> String:
	return step().extra_hint

func open_library() -> void:
	pass  # UI M2: диалог «Библиотека».

func _open_info(part_id: String) -> void:
	if part_id.is_empty():
		return
	info_part = part_id
	if not opened.has(part_id):
		opened.append(part_id)

## Подсветка для сцены: какую деталь и какой слот подсвечивать в текущей фазе.
func highlight_targets() -> Dictionary:
	if not started or finished:
		return {"parts": [], "slots": []}
	if phase == Phase.SELECT or phase == Phase.EXPLORE:
		return {"parts": [step().part_id], "slots": []}
	if phase == Phase.PLACE and not step().slot_id.is_empty():
		return {"parts": [], "slots": [step().slot_id]}
	return {"parts": [], "slots": []}

## Какую деталь можно схватить мышью (аналог setDraggable из веб-версии).
func grabbable_part() -> String:
	if started and not finished and step().kind == LessonStep.Kind.INSTALL \
			and (phase == Phase.SELECT or phase == Phase.PLACE):
		return step().part_id
	return ""
