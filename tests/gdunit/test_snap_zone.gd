extends GdUnitTestSuite
## Юнит-тесты слотов-«пазов» (gdUnit4): snap-радиус, активность, подсветка.

var _root: Node3D

func before_test() -> void:
	_root = Node3D.new()
	add_child(_root)

func after_test() -> void:
	_root.queue_free()

func test_contains_part_within_radius() -> void:
	var zone := SnapZone.new()
	zone.snap_radius = 2.5
	_root.add_child(zone)
	var part := Part.new()
	_root.add_child(part)
	zone.global_position = Vector3.ZERO
	part.global_position = Vector3(1.0, 0.0, 0.0)
	assert_bool(zone.contains_part(part)).is_true()
	part.global_position = Vector3(2.4, 0.0, 0.0)
	assert_bool(zone.contains_part(part)).is_true()

func test_contains_part_outside_radius() -> void:
	var zone := SnapZone.new()
	zone.snap_radius = 2.5
	_root.add_child(zone)
	var part := Part.new()
	_root.add_child(part)
	zone.global_position = Vector3.ZERO
	part.global_position = Vector3(5.0, 0.0, 0.0)
	assert_bool(zone.contains_part(part)).is_false()

func test_inactive_zone_stops_pulse() -> void:
	var zone := SnapZone.new()
	_root.add_child(zone)
	zone.set_active(true)
	assert_bool(zone.active).is_true()
	assert_int(zone.collision_layer).is_equal(4)
	zone.set_active(false)
	assert_bool(zone.active).is_false()
	assert_int(zone.collision_layer).is_equal(8)

func test_zone_active_changes_drag_visibility() -> void:
	# активный слот — слой 3 (маска 4), неактивный — слой 4 (маска 8)
	var zone := SnapZone.new()
	_root.add_child(zone)
	zone.set_active(true)
	assert_bool((zone.collision_layer & 4) != 0).is_true()
	assert_bool((zone.collision_layer & 8) == 0).is_true()
	zone.set_active(false)
	assert_bool((zone.collision_layer & 8) != 0).is_true()
	assert_bool((zone.collision_layer & 4) == 0).is_true()
