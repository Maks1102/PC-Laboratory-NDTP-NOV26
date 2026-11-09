class_name SnapZone
extends Area3D
## Слот-«паз» M1 (п.4 TODO): Area3D на целевой позиции + подсветка emission-пульсацией.
## Валидная деталь над слотом → подсветка; отпускание → main.gd зовёт GameState.pick_slot().

## id слота: "slot-cpu", "slot-ram", "slot-m2", "slot-pcie", "slot-psu", "slot-case".
@export var slot_id: String = ""
## Радиус допуска snap при отпускании (единицы сцены); у больших зон — больше.
@export var snap_radius: float = 2.5
## Родитель, к которому прикрепляется деталь после установки (мobo / корпус).
@export var target_parent: NodePath = NodePath("../..")
## Локальная позиция/вращение детали у target_parent после snap.
@export var snap_position: Vector3 = Vector3.ZERO
@export var snap_rotation: Vector3 = Vector3.ZERO
## Подсвечивать ли слот (true — когда он цель текущего шага).
var active := false

var _mesh: MeshInstance3D
var _base_mat: StandardMaterial3D
var _pulse := 0.0
var _candidate: Part = null

func _ready() -> void:
	# Подсветочный меш: полупрозрачный бокс по форме коллизии.
	var shape_node := _first_shape()
	if shape_node == null:
		return
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	if shape_node.shape is BoxShape3D:
		box.size = (shape_node.shape as BoxShape3D).size + Vector3(0.15, 0.15, 0.15)
	else:
		box.size = Vector3(3, 3, 3)
	_mesh.mesh = box
	_base_mat = StandardMaterial3D.new()
	_base_mat.albedo_color = Color(0.3, 1.0, 0.5, 0.18)
	_base_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_base_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_base_mat.emission_enabled = true
	_base_mat.emission = Color(0.3, 1.0, 0.5)
	_base_mat.emission_energy_multiplier = 0.4
	_mesh.material_override = _base_mat
	_mesh.position = shape_node.position
	_mesh.visible = false  # маркер виден только на своём шаге (set_active)
	add_child(_mesh)
	# Зона не должна ловить обычные клики-пикинг деталей: свой слой, маска пустая.
	collision_layer = 8  # неактивный стартовый слой (кликовый raycast)
	collision_mask = 0
	monitoring = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _first_shape() -> CollisionShape3D:
	for c in get_children():
		if c is CollisionShape3D:
			return c as CollisionShape3D
	return null

func _on_body_entered(body: Node3D) -> void:
	var p := body as Part
	if p != null:
		_candidate = p

func _on_body_exited(body: Node3D) -> void:
	var p := body as Part
	if p != null and p == _candidate:
		_candidate = null

## Есть ли деталь в допуске snap (по центру — расстоянию до зоны).
func contains_part(p: Part) -> bool:
	return global_position.distance_to(p.global_position) <= snap_radius

## Подсветка активного слота и ray-видимость.
## Активный слот: слой 3 (маска 4) — его видит raycast drag/подсветки.
## Неактивный: слой 4 (маска 8) — видит только кликовый raycast (клик даёт «не тот слот»).
func set_active(on: bool) -> void:
	active = on
	collision_layer = 4 if on else 8
	if _mesh != null:
		_mesh.visible = on  # маркер только на своём шаге сборки
	if not on:
		_candidate = null
		_apply(0.25, 0.12)

func _process(delta: float) -> void:
	if not active:
		return
	_pulse += delta * 3.5
	var k := 0.5 + 0.5 * sin(_pulse)
	_apply(0.6 + 0.9 * k, 0.15 + 0.15 * k)

func _apply(emission_energy: float, alpha: float) -> void:
	if _base_mat == null:
		return
	_base_mat.emission_energy_multiplier = emission_energy
	var c := _base_mat.albedo_color
	c.a = alpha
	_base_mat.albedo_color = c
