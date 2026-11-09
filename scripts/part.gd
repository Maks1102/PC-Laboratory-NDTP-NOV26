class_name Part
extends Node3D
## Базовая деталь M1: меш из .glb + Area3D для пикинга + подсветка.
## Пикинг и drag-логика — в scenes/main.gd; здесь только визуал и данные.

## id детали: "mobo", "cpu", "cooler", "ram", "ssd", "psu", "gpu".
@export var part_id: String = ""
## Карточка знаний (PartInfo.tres).
@export var info: PartInfo
## «Домашняя» трансформация на лотке — сюда деталь возвращается при отмене (локально в Parts).
@export var home_position: Vector3 = Vector3.ZERO
@export var home_rotation: Vector3 = Vector3.ZERO

var _meshes: Array[MeshInstance3D] = []
var _base_materials: Array[Material] = []
var _highlight := false
var _pulse := 0.0

func _ready() -> void:
	_collect_meshes(self)
	# Пикинг-область: если у сцены нет своей Area3D — создаём бокс по габаритам меша.
	if not _has_area():
		_add_default_area()

func _collect_meshes(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		_meshes.append(mi)
		var m: Material = mi.get_surface_override_material(0)
		if m == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			m = mi.mesh.surface_get_material(0)
		_base_materials.append(m)
	for c in n.get_children():
		_collect_meshes(c)

func _has_area() -> bool:
	return _find_pick_area(self) != null

## Нужна именно пикер-область на слое деталей (2), а не зоны-слоты (4).
func _find_pick_area(n: Node) -> Area3D:
	if n is Area3D and ((n as Area3D).collision_layer & 2) != 0:
		return n as Area3D
	for c in n.get_children():
		var r := _find_pick_area(c)
		if r != null:
			return r
	return null

## Дефолтный пикер: Area3D + бокс по объединённому габариту всех мешей.
func _add_default_area() -> void:
	var bounds := AABB()
	var first := true
	for mi in _meshes:
		var aabb := mi.get_aabb()
		for i in 8:
			var p := mi.transform * aabb.get_endpoint(i)
			if first:
				bounds = AABB(p, Vector3.ZERO)
				first = false
			else:
				bounds = bounds.expand(p)
	if first:
		return
	var area := Area3D.new()
	area.name = "PickArea"
	area.collision_layer = 2  # слой деталей (см. Main.tscn)
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = bounds.size + Vector3(0.1, 0.1, 0.1)
	shape.shape = box
	shape.position = bounds.get_center()
	area.add_child(shape)
	add_child(area)

## Подсветка активной детали (emission-пульсация) — вызывает main.gd.
func set_highlight(on: bool) -> void:
	_highlight = on
	if not on:
		_pulse = 0.0
	_apply_emission(Color(0.25, 0.9, 0.4), 0.0)

func _process(delta: float) -> void:
	if not _highlight:
		return
	_pulse += delta * 3.0
	var k := 0.12 + 0.28 * (0.5 + 0.5 * sin(_pulse))
	_apply_emission(Color(0.35, 1.0, 0.45), k)

func _apply_emission(color: Color, energy: float) -> void:
	for i in _meshes.size():
		var mi := _meshes[i]
		var base: Material = _base_materials[i] if i < _base_materials.size() else null
		if base == null:
			continue
		if energy <= 0.0:
			mi.set_surface_override_material(0, null)  # вернуть материал из меша
			continue
		if base is StandardMaterial3D:
			var m := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = energy
			mi.set_surface_override_material(0, m)
