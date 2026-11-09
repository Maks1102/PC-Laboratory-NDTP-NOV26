extends Node3D
## Скриншот-утилита M1: прогоняет все 8 шагов, сохраняет PNG каждого состояния.
## Запуск (нужен дисплей, GPU):
##   Godot --path . res://tests/screenshot.tscn
## Артефакты: tests/screenshots/*.png

const OUT_DIR := "res://tests/screenshots"

var _main: Node3D
var _actions: Array = []
var _idx := 0
var _wait := 0

func _ready() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	# Закрываем приветствие: кадры проверяют 3D-раскладку, диалог её заслоняет.
	var ui := _main.get_node_or_null("UILayer/UI")
	if ui:
		var dialog := ui.get_node_or_null("Dialog")
		if dialog:
			dialog.visible = false
	_actions = [
		["shoot", "01-mobo", 30],
		["step", null, 0],
		["shoot", "02-cpu", 40],
		["step", null, 0],
		["shoot", "03-cooler", 40],
		["step", null, 0],
		["shoot", "04-ram", 40],
		["step", null, 0],
		["shoot", "05-ssd", 40],
		["step", null, 0],
		["shoot", "06-mobo-case", 40],
		["step", null, 0],
		["shoot", "07-psu", 60],
		["step", null, 0],
		["shoot", "08-gpu", 60],
		["step", null, 0],
		["shoot", "09-final", 60],
		["step", null, 0],
		["shoot", "10-done", 40],
		["quit", null, 0],
	]

func _process(_delta: float) -> void:
	if _idx >= _actions.size():
		return
	var a: Array = _actions[_idx]
	_wait += 1
	if _wait < int(a[2]):
		return
	match a[0]:
		"shoot":
			_save(String(a[1]))
			print("SHOT ", a[1])
		"step":
			_complete_current_step()
			print("STEP done -> ", GameState.step().id)
		"quit":
			get_tree().quit(0)
	_idx += 1
	_wait = 0

## Повторяет то, что сделал бы игрок: выбирает деталь и слот текущего шага.
func _complete_current_step() -> void:
	var step: LessonStep = GameState.step()
	if step.kind == LessonStep.Kind.EXPLORE:
		GameState.pick_part(step.part_id)
		GameState.next_step()
		return
	GameState.pick_part(step.part_id)
	GameState.pick_slot(step.slot_id)
	GameState.next_step()

func _save(name: String) -> void:
	var dir := DirAccess.open("res://")
	if dir != null and not dir.dir_exists(OUT_DIR):
		dir.make_dir_recursive(OUT_DIR)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png("%s/%s.png" % [OUT_DIR, name])
	if err != OK:
		printerr("save_png failed: ", err)
