extends SceneTree
## Генератор resources/lesson_sequence.tres из 8 .tres-шагов.
## Шаги правятся в отдельных .tres; этот скрипт только собирает последовательность.
## Запуск: Godot --headless --path . --script res://tests/gen_sequence.gd

const STEP_IDS: Array[String] = [
	"step-mobo", "step-cpu", "step-cooler", "step-ram",
	"step-ssd", "step-mobo-case", "step-psu", "step-gpu",
]

func _init() -> void:
	var seq := LessonSequence.new()
	for id in STEP_IDS:
		var path := "res://resources/lessons/%s.tres" % id
		var step: LessonStep = load(path)
		if step == null:
			printerr("FAIL: не загрузился " + path)
			quit(1)
			return
		seq.steps.append(step)
	if seq.steps.size() != 8:
		printerr("FAIL: ожидалось 8 шагов, получено %d" % seq.steps.size())
		quit(1)
		return
	var err := ResourceSaver.save(seq, "res://resources/lesson_sequence.tres")
	if err != OK:
		printerr("FAIL: ошибка сохранения %d" % err)
		quit(1)
		return
	print("GEN_SEQUENCE: OK (8 шагов → res://resources/lesson_sequence.tres)")
	quit(0)
