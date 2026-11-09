extends Node3D
## Главная сцена M1: мир + детали + слоты + камера.
## Здесь — пикинг (луч), порог «клик vs драг» (8 px), перетаскивание,
## snap-логика и анимации установки (п.4 TODO). Стейт-машина — в GameState.

const CLICK_PX := 8.0

var _camera: Camera3D
var _parts: Array[Part] = []
var _zones: Array[SnapZone] = []

var _press_pos := Vector2.ZERO
var _press_part: Part = null
var _press_zone: SnapZone = null
var _dragging := false
var _drag_part: Part = null
var _drag_distance := 0.0
var _pending_zone: SnapZone = null
var _last_targets := {"parts": [], "slots": []}
## Финал: вентиляторы и LED корпуса.
var _fan_rotors: Array[Node3D] = []
var _fan_speed := 0.0
var _fan_target := 0.0
var _led_meshes: Array[MeshInstance3D] = []
var _led_on := false
var _led_time := 0.0

func _ready() -> void:
	_camera = $CameraRig/Yaw/Pitch/Camera3D
	_collect()
	_find_case_power_meshes($Case)
	EventBus.part_installed.connect(_on_part_installed)
	EventBus.step_changed.connect(_on_step_changed)
	EventBus.power_on.connect(_on_power_on)
	EventBus.power_off.connect(_on_power_off)
	GameState.start()
	var step := GameState.step()
	$CameraRig.focus_on(step.focus, step.cam, true)
	_apply_highlights()
	print("[Main] M1 сцена готова | деталей=%d слотов=%d | шаг=%s фаза=%d" % [
		_parts.size(), _zones.size(), GameState.step().id, GameState.phase])

func _collect() -> void:
	_parts.clear()
	_zones.clear()
	_find_type(self, Part, _parts)
	_find_type(self, SnapZone, _zones)

func _find_type(n: Node, type, out: Array) -> void:
	if is_instance_of(n, type):
		out.append(n)
	for c in n.get_children():
		_find_type(c, type, out)

## Ротор = родитель хаба вентилятора (материал …_0h8at); LED = меши с материалом …_yoc3v.
## Имена материалов при выгрузке из Three.js стабильны; сверху есть запасной вариант по имени узла.
func _find_case_power_meshes(n: Node) -> void:
	if n.name in ["95", "75", "55", "35"] and n is Node3D and not _fan_rotors.has(n):
		_fan_rotors.append(n as Node3D)
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mat := mi.mesh.surface_get_material(0) if mi.mesh != null and mi.mesh.get_surface_count() > 0 else null
		if mat != null:
			var p := mat.resource_path
			if p.ends_with("_0h8at"):
				var rotor := mi.get_parent()
				if rotor is Node3D and not _fan_rotors.has(rotor):
					_fan_rotors.append(rotor as Node3D)
			elif p.ends_with("_yoc3v"):
				_led_meshes.append(mi)
	for c in n.get_children():
		_find_case_power_meshes(c)

# --- ввод: пикинг, клик vs драг, перетаскивание ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_press_pos = mb.position
			var part := _pick_part(mb.position)
			var zone := _pick_zone(mb.position, 12) if part == null else null
			_press_part = part
			_press_zone = zone
		else:
			_release(mb.position)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _press_part != null and not _dragging:
			# Порог «клик vs драг»: > 8 px и деталь берёмная → начинаем drag.
			if _press_pos.distance_to(mm.position) >= CLICK_PX and _can_grab(_press_part):
				_begin_drag(_press_part)
		if _dragging and _drag_part != null:
			_update_drag(mm.position)

func _release(pos: Vector2) -> void:
	var was_part := _press_part
	var was_zone := _press_zone
	_press_part = null
	_press_zone = null
	if _dragging:
		_end_drag(pos)
		return
	# Обычный клик (< 8 px): деталь или слот → стейт-машина.
	if was_part != null:
		GameState.pick_part(was_part.part_id)
	elif was_zone != null:
		GameState.pick_slot(was_zone.slot_id)
	_apply_highlights()

func _can_grab(part: Part) -> bool:
	return GameState.grabbable_part() == part.part_id

func _begin_drag(part: Part) -> void:
	_dragging = true
	_drag_part = part
	_drag_distance = _camera.global_position.distance_to(part.global_position)
	GameState.drag_start(part.part_id)
	_apply_highlights()

func _update_drag(pos: Vector2) -> void:
	# Деталь едет по лучу камеры: если луч указывает на активный слот — кладём на него,
	# иначе на фиксированном удалении от камеры (следует за курсором).
	var from := _camera.project_ray_origin(pos)
	var dir := _camera.project_ray_normal(pos)
	var zone := _zone_hit_by_ray(pos)
	if zone != null:
		_drag_part.global_position = zone.global_position
		return
	_drag_part.global_position = from + dir * _drag_distance
	_apply_highlights()

func _end_drag(pos: Vector2) -> void:
	var part := _drag_part
	_dragging = false
	_drag_part = null
	if part == null:
		return
	var zone := _zone_hit_by_ray(pos)
	if zone == null:
		zone = _nearest_zone(part)
	if zone != null:
		_pending_zone = zone
		GameState.drag_dropped(zone.slot_id)  # валидация в стейт-машине
		if GameState.phase != GameState.Phase.CARD:
			_return_home(part)  # неверный слот → вернуть на лоток
			_pending_zone = null
	else:
		GameState.drag_cancelled()
		_return_home(part)
	_apply_highlights()

## Возврат детали на лоток (tween, п.4 TODO).
func _return_home(part: Part) -> void:
	var home := Transform3D(Basis.from_euler(part.home_rotation), part.home_position)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(part, "global_transform", home, 0.4)

# --- поиск объектов лучом ---

func _pick_part(screen_pos: Vector2) -> Part:
	var hit := _ray(screen_pos, 2, true)
	if hit.is_empty():
		return null
	var node: Node = hit["collider"]
	while node != null and not (node is Part):
		node = node.get_parent()
	return node as Part

func _pick_zone(screen_pos: Vector2, mask: int = 4) -> SnapZone:
	var hit := _ray(screen_pos, mask, true)
	if hit.is_empty():
		return null
	return hit["collider"] as SnapZone

func _zone_hit_by_ray(screen_pos: Vector2) -> SnapZone:
	# При drag-подсказке и дропе учитываем только активный слот текущего шага
	# (остальные зоны ловит только клик — он даёт сообщение о неверном слоте).
	var z := _pick_zone(screen_pos)
	if z != null and z.active:
		return z
	return null

func _nearest_zone(part: Part) -> SnapZone:
	var best: SnapZone = null
	var best_d := INF
	for z in _zones:
		if not z.active:
			continue
		var d := z.global_position.distance_to(part.global_position)
		if d < z.snap_radius and d < best_d:
			best = z
			best_d = d
	return best

func _ray(screen_pos: Vector2, mask: int, areas: bool) -> Dictionary:
	var from := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 600.0, mask)
	query.collide_with_areas = areas
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query)

# --- установка (snap + tween + перепривязка) ---

func _on_part_installed(part_id: String) -> void:
	var part := _part_by_id(part_id)
	if part == null:
		return
	var zone := _pending_zone
	_pending_zone = null
	if zone == null:
		zone = _zone_by_slot(GameState.step().slot_id)
	if zone == null:
		return
	var parent: Node = zone.get_node_or_null(zone.target_parent)
	if parent == null or not (parent is Node3D):
		return
	# Плата и БП едут в корпус отдельно от верстака/стенда: отвязываем от
	# текущего родителя ДО твина, сохраняя глобальный трансформ (п.6 TODO).
	if part.get_parent() != parent:
		var keep := part.global_transform
		part.reparent(get_tree().root, false)
		part.global_transform = keep
	var snap_local := Transform3D(Basis.from_euler(zone.snap_rotation), zone.snap_position)
	var target_world: Transform3D = (parent as Node3D).global_transform * snap_local
	var tw := create_tween()
	# Плата и БП — «долгий перелёт», остальные детали — короткий snap.
	var duration := 0.9 if part_id in ["mobo", "psu"] else 0.45
	if part_id in ["mobo", "psu"]:
		tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(part, "global_transform", target_world, duration)
	# Лёгкий scale-bounce установки (п.6 P1).
	part.scale = Vector3(1.12, 1.12, 1.12)
	var tw2 := create_tween()
	tw2.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw2.tween_property(part, "scale", Vector3.ONE, 0.6)
	tw.finished.connect(func() -> void:
		part.reparent(parent, true)
		part.transform = snap_local
	)
	_apply_highlights()

func _on_step_changed(step_id: String) -> void:
	# Полный reset (назад на шаг 0) → вернуть все детали «домой».
	if step_id == "step-mobo" and GameState.installed.is_empty():
		_reset_parts()
	_apply_highlights()

func _reset_parts() -> void:
	var parts_root := $Parts
	for p in _parts:
		if p.get_parent() != parts_root:
			p.reparent(parts_root, false)
		p.transform = Transform3D(Basis.from_euler(p.home_rotation), p.home_position)
		p.scale = Vector3.ONE
		p.set_highlight(false)

# --- подсветка целей текущего шага (п.4 P1) ---

func _apply_highlights() -> void:
	var targets: Dictionary = GameState.highlight_targets()
	var parts: Array = targets["parts"]
	var slots: Array = targets["slots"]
	if parts == _last_targets["parts"] and slots == _last_targets["slots"]:
		return
	_last_targets = {"parts": parts.duplicate(), "slots": slots.duplicate()}
	for p in _parts:
		p.set_highlight(parts.has(p.part_id))
	for z in _zones:
		z.set_active(slots.has(z.slot_id))

func _part_by_id(id: String) -> Part:
	for p in _parts:
		if p.part_id == id:
			return p
	return null

func _zone_by_slot(id: String) -> SnapZone:
	for z in _zones:
		if z.slot_id == id:
			return z
	return null

# --- питание (финал: POST, вентиляторы, LED) ---

func _on_power_on() -> void:
	_fan_target = 11.0
	_led_on = true
	for mi in _led_meshes:
		var base := mi.mesh.surface_get_material(0) as StandardMaterial3D
		if base == null:
			continue
		var m := base.duplicate() as StandardMaterial3D
		m.emission_enabled = true
		m.emission = Color(0.25, 1.0, 0.4)
		m.emission_energy_multiplier = 0.0
		mi.set_surface_override_material(0, m)
	var inner := get_node_or_null("Case/InteriorLight")
	if inner is OmniLight3D:
		var tw := create_tween()
		(inner as OmniLight3D).light_energy = 0.0
		tw.tween_property(inner, "light_energy", 2.4, 1.2)

func _on_power_off() -> void:
	_fan_target = 0.0
	_led_on = false
	for mi in _led_meshes:
		mi.set_surface_override_material(0, null)  # вернуть исходный материал
	var inner := get_node_or_null("Case/InteriorLight")
	if inner is OmniLight3D:
		(inner as OmniLight3D).light_energy = 0.0

func _process(delta: float) -> void:
	if not is_equal_approx(_fan_speed, _fan_target):
		_fan_speed = move_toward(_fan_speed, _fan_target, delta * 5.0)
		for r in _fan_rotors:
			r.rotate_z(-_fan_speed * delta if r.global_position.z > 14.0 else _fan_speed * delta)
	if _led_on:
		_led_time += delta
		var k := 1.5 + 0.9 * sin(_led_time * 2.6)
		for mi in _led_meshes:
			var m := mi.get_surface_override_material(0) as StandardMaterial3D
			if m != null:
				m.emission_energy_multiplier = k