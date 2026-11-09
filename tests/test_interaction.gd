extends Node3D
## Тест ввода M1: симуляция ЛКМ/мыши поверх главной сцены.
## Проверяет: клик по детали (EXPLORE→CARD), drag CPU в сокет,
## drag «мимо» (возврат детали), клик по неверной детали (отказ).
## Запуск: Godot --headless --path . res://tests/test_interaction.tscn

var fails: Array[String] = []
var rejected: Array[String] = []
var installed: Array[String] = []

var _main: Node3D
var _cam: Camera3D

func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)

func _ready() -> void:
	EventBus.part_rejected.connect(func(r: String) -> void: rejected.append(r))
	EventBus.part_installed.connect(func(id: String) -> void: installed.append(id))
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	_cam = _main.get_node("CameraRig/Yaw/Pitch/Camera3D")
	GameState.start()
	await get_tree().process_frame

	await _test_explore_click()
	_test_wrong_part_click()
	await _test_drag_cancel_returns_home()
	await _test_cpu_drag_installs()

	if fails.is_empty():
		print("TEST_INTERACTION: PASS")
		get_tree().quit(0)
	else:
		for f in fails:
			printerr("FAIL: " + f)
		print("TEST_INTERACTION: FAIL (%d)" % fails.size())
		get_tree().quit(1)

# --- утилиты ввода ---

func _screen_pos(world: Vector3) -> Vector2:
	return _cam.unproject_position(world)

func _mouse_button(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = pos
	return ev

func _mouse_motion(pos: Vector2) -> InputEventMouseMotion:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	return ev

func _click(pos: Vector2) -> void:
	_main._unhandled_input(_mouse_button(pos, true))
	_main._unhandled_input(_mouse_button(pos, false))

## Перетаскивание из from_pos в to_pos: нажатие, ряд движений, отпускание.
func _drag(from_pos: Vector2, to_pos: Vector2) -> void:
	_main._unhandled_input(_mouse_button(from_pos, true))
	for i in range(1, 11):
		var p := from_pos.lerp(to_pos, float(i) / 10.0)
		_main._unhandled_input(_mouse_motion(p))
	_main._unhandled_input(_mouse_button(to_pos, false))

# --- тесты ---

func _test_explore_click() -> void:
	# Шаг 0: EXPLORE — кликаем по плате, ожидаем карточку (CARD).
	var mobo: Node3D = _main.get_node("Parts/Mobo")
	_click(_screen_pos(mobo.global_position + Vector3(0, 0.3, 0)))
	_check(GameState.phase == GameState.Phase.CARD, "клик по плате → фаза CARD, получено %d" % GameState.phase)
	_check(GameState.opened.has("mobo"), "mobo в opened")
	GameState.next_step()  # → step-cpu
	await get_tree().create_timer(1.0).timeout  # дожидаемся переезда камеры

func _test_wrong_part_click() -> void:
	# Шаг 1: SELECT — клик по gpu → отказ.
	var before := rejected.size()
	var gpu: Node3D = _main.get_node("Parts/Gpu")
	_click(_screen_pos(gpu.global_position + Vector3(0, 1.0, 0)))
	_check(rejected.size() == before + 1, "клик по чужой детали → part_rejected")
	_check(GameState.phase == GameState.Phase.SELECT, "фаза SELECT не сменилась")

func _test_drag_cancel_returns_home() -> void:	# Берём CPU и «роняем» на пустое место → возврат домой, отказ.
	var cpu: Node3D = _main.get_node("Parts/Cpu")
	var home: Vector3 = cpu.home_position
	var before := rejected.size()
	_drag(_screen_pos(cpu.global_position + Vector3(0, 0.2, 0)), Vector2(5.0, 5.0))
	await get_tree().create_timer(0.7).timeout  # дожидаемся tween возврата на лоток
	_check(rejected.size() == before + 1, "дроп мимо → part_rejected")
	_check(GameState.is_dragging == false, "is_dragging снят после дроп-cancel")
	_check(cpu.global_position.distance_to(home) < 0.5,
			"cpu вернулась на лоток (dist=%f)" % cpu.global_position.distance_to(home))

func _test_cpu_drag_installs() -> void:
	# Тащим CPU в сокет: после дропа он установлен и прикреплён к плате.
	var cpu: Node3D = _main.get_node("Parts/Cpu")
	var slot: Node3D = _main.get_node("Parts/Mobo/SlotCpu")
	_drag(_screen_pos(cpu.global_position + Vector3(0, 0.2, 0)), _screen_pos(slot.global_position))
	_check(installed.has("cpu"), "cpu установлена (installed=%s)" % [installed])
	_check(GameState.phase == GameState.Phase.CARD, "после установки фаза CARD")
	await get_tree().create_timer(0.6).timeout  # дать завершиться tween
	_check(cpu.get_parent().name == "Mobo", "cpu прикреплена к плате, parent=%s" % cpu.get_parent().name)
