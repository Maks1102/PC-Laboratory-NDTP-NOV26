class_name HintZone
extends Node3D
## Зона-подсказка пунктиром (п.4 P1 TODO): ImmediateMesh с сегментами по рёбрам бокса.
## Не имеет коллизии вообще — raycast её не видит. Скрывается после установки (step 5/6).

@export var box_size: Vector3 = Vector3(6, 10, 8)
@export var hide_after_part: String = ""  # part_id: скрыть после part_installed
@export var dash_len := 0.55
@export var gap_len := 0.35
@export var line_width := 0.09

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D

func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Dashes"
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(1.0, 0.85, 0.2, 0.9)
	_material.emission_enabled = true
	_material.emission = Color(1.0, 0.8, 0.2)
	_material.emission_energy_multiplier = 0.8
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh_instance.material_override = _material
	add_child(_mesh_instance)
	_rebuild()
	EventBus.part_installed.connect(_on_part_installed)
	set_visible(true)

func _on_part_installed(part_id: String) -> void:
	if part_id == hide_after_part:
		visible = false

func _rebuild() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := box_size * 0.5
	# 12 рёбр бокса: каждое — пунктир (параллелепипеды-штрихи).
	var edges: Array = [
		[Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z)],
		[Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)],
		[Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z)],
		[Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z)],
		[Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z)],
		[Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z)],
		[Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z)],
		[Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z)],
		[Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z)],
		[Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z)],
		[Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)],
	]
	for e in edges:
		_dash_edge(im, e[0], e[1])
	im.surface_end()
	_mesh_instance.mesh = im

## Штрихи-параллелепипеды вдоль отрезка a→b.
func _dash_edge(im: ImmediateMesh, a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var length := dir.length()
	if length < 0.001:
		return
	dir = dir / length
	# Ортонормальный базис: вдоль ребра + два перпендикуляра шириной line_width.
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var side := dir.cross(up).normalized()
	var thick := side.cross(dir).normalized() * (line_width * 0.5)
	var side_off := side * (line_width * 0.5)
	var t := 0.0
	while t < length:
		var seg := minf(dash_len, length - t)
		var p0 := a + dir * t
		var p1 := p0 + dir * seg
		_box(im, p0, p1, side_off, thick)
		t += seg + gap_len

## 8 вершин бокса p0→p1 со смещениями ±side ±thick → 12 треугольников.
func _box(im: ImmediateMesh, p0: Vector3, p1: Vector3, side: Vector3, thick: Vector3) -> void:
	var v: Array[Vector3] = [
		p0 - side - thick, p0 + side - thick, p0 + side + thick, p0 - side + thick,
		p1 - side - thick, p1 + side - thick, p1 + side + thick, p1 - side + thick,
	]
	var quads: Array = [
		[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7],
		[1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0],
	]
	for q in quads:
		var a: Vector3 = v[q[0]]
		var b: Vector3 = v[q[1]]
		var c: Vector3 = v[q[2]]
		var d: Vector3 = v[q[3]]
		im.surface_add_vertex(a)
		im.surface_add_vertex(b)
		im.surface_add_vertex(c)
		im.surface_add_vertex(a)
		im.surface_add_vertex(c)
		im.surface_add_vertex(d)
