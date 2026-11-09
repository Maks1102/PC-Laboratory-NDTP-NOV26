extends Control
## Финальная POST-последовательность (п.6 TODO, P0): строки самопроверки,
## звуковой beep (генерируется в коде), затем сигнал boot_finished —
## ui_root показывает финал-поздравление. Вентиляторы и LED включает сцена
## по EventBus.power_on.

signal boot_finished

const LINES := [
	"POST — Power-On Self-Test",
	"CPU: OK",
	"Memory: 32768 MB DDR5 — OK",
	"Storage: NVMe SSD 1 TB — OK",
	"GPU: OK",
	"Firmware: проверка завершена",
	"All checks passed. Starting OS…",
]
const LINE_DELAY := 0.42
const AFTER_LAST_DELAY := 1.1

var _running := false

@onready var _lines_box: VBoxContainer = $Content/Lines
@onready var _skip: Button = $SkipButton

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	_skip.pressed.connect(_finish)

func run() -> void:
	_running = true
	visible = true
	modulate.a = 1.0
	for child in _lines_box.get_children():
		child.queue_free()
	_play_beep()
	var t := 0.15
	for line in LINES:
		var at := t
		get_tree().create_timer(at).timeout.connect(_add_line.bind(line))
		t += LINE_DELAY
	get_tree().create_timer(t + AFTER_LAST_DELAY).timeout.connect(_finish)

func _add_line(text: String) -> void:
	if not _running:
		return
	var label := Label.new()
	label.text = "> " + text
	label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55, 1))
	label.add_theme_font_size_override("font_size", 20)
	_lines_box.add_child(label)

func _finish() -> void:
	if not _running:
		return
	_running = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		visible = false
		modulate.a = 1.0
		boot_finished.emit())

## Короткий beep 880 Гц, 0.16 с — как динамик на материнской плате.
func _play_beep() -> void:
	var rate := 44100
	var duration := 0.16
	var samples := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / rate
		var attack := minf(t / 0.008, 1.0)
		var release := minf((duration - t) / 0.03, 1.0)
		var envelope := minf(attack, release)
		var sample := int(sin(TAU * 880.0 * t) * 14000.0 * envelope)
		data[i * 2] = sample & 0xff
		data[i * 2 + 1] = (sample >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = wav
	player.finished.connect(player.queue_free)
	player.play()
