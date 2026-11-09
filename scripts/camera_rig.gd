extends Node3D
## Орбитальная камера M1 (п.3 TODO): CameraRig → Yaw → Pitch → Camera3D.
## ЛКМ по пустому месту — орбита (не по детали!), ПКМ — панорама, колесо — зум.
## Во время перетаскивания (GameState.is_dragging) ввод полностью игнорируется.

@export var orbit_speed := 0.0055
@export var pan_speed := 0.02
@export var zoom_speed := 0.012
@export var min_distance := 4.0
@export var max_distance := 55.0
@export var min_pitch := -1.35   # не уходит под пол
@export var max_pitch := 1.30
@export var smoothness := 14.0   # экспоненциальное сглаживание (п.3 P1)

## Порог «клик vs драг»: смещение < 8 px = клик (обрабатывает main.gd).
const CLICK_THRESHOLD_PX := 8.0

var _yaw := 0.0
var _pitch := -0.35
var _distance := 16.0
var _target_yaw := 0.0
var _target_pitch := -0.35
var _target_distance := 16.0
var _focus := Vector3.ZERO            # точка орбиты (look-at)
var _target_focus := Vector3.ZERO

var _orbiting := false
var _panning := false
var _last_mouse := Vector2.ZERO
var _press_pos := Vector2.ZERO
var _pressed_button := -1

@onready var _yaw_node: Node3D = $Yaw
@onready var _pitch_node: Node3D = $Yaw/Pitch
@onready var _camera: Camera3D = $Yaw/Pitch/Camera3D

func _ready() -> void:
	_apply_immediate()
	EventBus.step_changed.connect(_on_step_changed)
	EventBus.assembly_completed.connect(_on_assembly_completed)

## Фокус шага: focus — точка орбиты, cam — дополнительный сдвиг самой камеры (п.3 P1).
func focus_on(focus: Vector3, cam_offset: Vector3, instant := false) -> void:
	_target_focus = focus
	# cam ≠ 0 — заданная позиция камеры: вычисляем дистанцию/углы из неё.
	if cam_offset != Vector3.ZERO:
		var offset: Vector3 = cam_offset - focus
		_target_distance = clampf(offset.length(), min_distance, max_distance)
		_target_yaw = atan2(offset.x, offset.z)
		_target_pitch = clampf(-asin(offset.y / maxf(offset.length(), 0.001)), min_pitch, max_pitch)
	if instant:
		_yaw = _target_yaw
		_pitch = _target_pitch
		_distance = _target_distance
		_focus = _target_focus
		_apply_immediate()

func _on_step_changed(_step_id: String) -> void:
	var step := GameState.step()
	focus_on(step.focus, step.cam)

func _on_assembly_completed() -> void:
	# Финал: отъехать к корпусу на полу для осмотра результата.
	focus_on(Vector3(14.0, 9.5, 20.0), Vector3(29.5, 13.5, 37.0))

func _unhandled_input(event: InputEvent) -> void:
	# П.3 P0: во время драга камера полностью игнорирует ввод.
	if GameState.is_dragging:
		_orbiting = false
		_panning = false
		return
	# Клик по детали не должен вращать камеру: проверяем слой деталей (Area3D).

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed:
				var sign := 1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
				_target_distance = clampf(_target_distance * (1.0 - sign * zoom_speed * 10.0),
						min_distance, max_distance)
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press_pos = mb.position
				_last_mouse = mb.position
				_pressed_button = MOUSE_BUTTON_LEFT
				# Орбита — только ЛКМ по пустому месту (не по детали!).
				if not _pointer_over_pickable(mb.position):
					_orbiting = true
			elif _pressed_button == MOUSE_BUTTON_LEFT:
				_orbiting = false
				_pressed_button = -1
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_press_pos = mb.position
				_last_mouse = mb.position
				_pressed_button = MOUSE_BUTTON_RIGHT
				_panning = true
			elif _pressed_button == MOUSE_BUTTON_RIGHT:
				_panning = false
				_pressed_button = -1
			return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _orbiting:
			_target_yaw -= mm.relative.x * orbit_speed
			_target_pitch = clampf(_target_pitch - mm.relative.y * orbit_speed, min_pitch, max_pitch)
		elif _panning:
			var right := _camera.global_transform.basis.x
			var up := _camera.global_transform.basis.y
			var k := _target_distance * pan_speed * 0.12
			_target_focus += (-right * mm.relative.x + up * mm.relative.y) * k
		return

## Порог «клик vs драг» (п.3 P0): вызывает main.gd при отпускании ЛКМ.
static func is_click(press: Vector2, release: Vector2) -> bool:
	return press.distance_to(release) < CLICK_THRESHOLD_PX

## Есть ли под указателем «кликабельная» деталь (слой 2) — чтобы не вращать камеру.
func _pointer_over_pickable(screen_pos: Vector2) -> bool:
	var from := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 500.0, 2)  # маска: слой деталей
	query.collide_with_areas = true
	var hit := space.intersect_ray(query)
	return not hit.is_empty()

func _process(delta: float) -> void:
	var w := 1.0 - exp(-smoothness * delta)  # экспоненциальное сглаживание
	_yaw = lerpf(_yaw, _target_yaw, w)
	_pitch = lerpf(_pitch, _target_pitch, w)
	_distance = lerpf(_distance, _target_distance, w)
	_focus = _focus.lerp(_target_focus, w)
	_apply_immediate()

func _apply_immediate() -> void:
	_yaw_node.rotation = Vector3(0.0, _yaw, 0.0)
	_pitch_node.rotation = Vector3(_pitch, 0.0, 0.0)
	_camera.position = Vector3(0.0, 0.0, _distance)
	_yaw_node.position = _focus
