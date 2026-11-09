extends GdUnitTestSuite
## Юнит-тесты зон-подсказок (gdUnit4): скрытие после установки (п.5/6 TODO),
## отсутствие коллизии.

var _root: Node3D

func before_test() -> void:
	_root = Node3D.new()
	add_child(_root)

func after_test() -> void:
	_root.queue_free()

func test_hint_zone_is_visible_by_default() -> void:
	var zone := HintZone.new()
	zone.hide_after_part = "mobo"
	zone.box_size = Vector3(2, 2, 2)
	_root.add_child(zone)
	assert_bool(zone.visible).is_true()

func test_hint_zone_hides_after_matching_part_installed() -> void:
	var zone := HintZone.new()
	zone.hide_after_part = "mobo"
	zone.box_size = Vector3(2, 2, 2)
	_root.add_child(zone)
	EventBus.part_installed.emit("mobo")
	assert_bool(zone.visible).is_false()

func test_hint_zone_ignores_other_parts() -> void:
	var zone := HintZone.new()
	zone.hide_after_part = "psu"
	zone.box_size = Vector3(2, 2, 2)
	_root.add_child(zone)
	EventBus.part_installed.emit("mobo")
	assert_bool(zone.visible).is_true()
	EventBus.part_installed.emit("psu")
	assert_bool(zone.visible).is_false()

func test_hint_zone_has_no_collision() -> void:
	var zone := HintZone.new()
	_root.add_child(zone)
	assert_object(zone.find_child("CollisionShape3D", true, false)).is_null()
	for child in zone.get_children():
		assert_object(child as CollisionShape3D).is_null()
