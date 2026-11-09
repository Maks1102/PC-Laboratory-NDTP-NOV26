extends SceneTree
## Временный отладочный скрипт M1: иерархия и габариты всех .glb моделей.
## Запуск: Godot --headless --path . --script res://tests/inspect_models.gd

const MODELS: Array[String] = [
	"mobo", "cpu", "cooler", "ram", "ssd", "psu", "gpu", "case", "bench", "mobo-stand",
]

func _init() -> void:
	for f in MODELS:
		var path := "res://assets/models/%s.glb" % f
		var ps: PackedScene = load(path)
		if ps == null:
			print("LOAD_FAIL ", path)
			continue
		var root := ps.instantiate()
		print("=== ", f, " | root=", root.get_class(), " name=", root.name)
		_print(root, 1, Transform3D.IDENTITY)
		var aabb := _bounds(root, Transform3D.IDENTITY)
		print("    TOTAL AABB: pos=", aabb.position, " size=", aabb.size)
		root.free()
	quit(0)

func _print(n: Node, depth: int, parent_xf: Transform3D) -> void:
	var xf := parent_xf
	var ind := ""
	for i in depth:
		ind += "  "
	if n is Node3D:
		var n3 := n as Node3D
		xf = parent_xf * n3.transform
		var extra := ""
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var m := mi.get_aabb()
			extra = " | mesh_aabb pos=%s size=%s" % [m.position, m.size]
			if mi.mesh != null and mi.mesh.get_surface_count() > 0:
				extra += " | surf0=%s" % mi.mesh.surface_get_material(0).resource_path
		print(ind, n.name, " (", n.get_class(), ") pos=", (n3 as Node3D).position, extra)
	else:
		print(ind, n.name, " (", n.get_class(), ")")
	for c in n.get_children():
		_print(c, depth + 1, xf)

func _bounds(n: Node, xf: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [[n, xf]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var t: Transform3D = item[1]
		var cur := t
		if node is Node3D:
			cur = t * (node as Node3D).transform
		if node is MeshInstance3D:
			var local: AABB = (node as MeshInstance3D).get_aabb()
			for i in 8:
				var corner := local.get_endpoint(i)
				var world: Vector3 = cur * corner
				if first:
					result = AABB(world, Vector3.ZERO)
					first = false
				else:
					result = result.expand(world)
		for c in node.get_children():
			stack.push_back([c, cur])
	return result
