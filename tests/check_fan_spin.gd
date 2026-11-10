extends Node3D
## Регрессионный тест: вентиляторы крутятся непрерывно после power_on (баг «раскрутка → замерли»).
## Запуск: godot --headless --path . res://tests/check_fan_spin.tscn   → CHECK_FAN_SPIN: PASS/FAIL
var _main: Node3D
var _frames := 0
var _first := []
var _t0 := 0

func _ready() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)

func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 10:
		print("rotors found: ", _main._fan_rotors.size())
		EventBus.power_on.emit()
	elif _frames == 150:
		_first = []
		for r in _main._fan_rotors:
			_first.append(r.rotation.z)
		_t0 = _frames
		print("rotation t0: ", _first)
	elif _frames > 150 and _frames == 150 + 90:
		var moved := 0
		for i in _main._fan_rotors.size():
			var cur: float = _main._fan_rotors[i].rotation.z
			var diff := absf(wrapf(cur - _first[i], -PI, PI))
			print("rotor %d moved by %.3f rad" % [i, diff])
			if diff > 2.0:
				moved += 1
		print("fans continuously spinning: %s" % ("YES" if moved == _main._fan_rotors.size() else "NO"))
		if _main._fan_rotors.size() > 0 and moved == _main._fan_rotors.size():
			print("CHECK_FAN_SPIN: PASS")
			get_tree().quit(0)
		else:
			print("CHECK_FAN_SPIN: FAIL")
			get_tree().quit(1)
