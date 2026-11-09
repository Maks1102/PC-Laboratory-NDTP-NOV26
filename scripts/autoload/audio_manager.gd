extends Node
## Автолоад AudioManager (п.7 TODO): звук по шинам Master/SFX/Music.
## Если в res://assets/audio/<name>.{wav,ogg} лежит файл — играется он
## (замена плейсхолдеров на пользовательские ассеты — просто копированием файлов).
## Если файла нет — играется процедурный плейсхолдер (проект собирается без ассетов).
##
## Имена файлов: click, snap, error, success, ambient, fan. См. assets/audio/README.md.

const AUDIO_DIR := "res://assets/audio"
const SAMPLE_RATE := 22050

var _streams: Dictionary = {}
var _ambience_player: AudioStreamPlayer
var _fan_player: AudioStreamPlayer3D

func _ready() -> void:
	for name in ["click", "snap", "error", "success", "power", "ambient", "fan"]:
		var stream := _load_or_make(name)
		if stream != null:
			_streams[name] = stream
	EventBus.part_installed.connect(_on_part_installed)
	EventBus.part_rejected.connect(func(_reason: String) -> void: play_sfx("error"))
	EventBus.assembly_completed.connect(func() -> void: play_sfx("success"))
	EventBus.power_on.connect(_on_power_on)
	EventBus.power_off.connect(_on_power_off)
	EventBus.step_changed.connect(func(step_id: String) -> void:
		if step_id == "step-mobo" and GameState.installed.is_empty():
			_stop_fan())
	_start_ambience()

## Громкий одноразовый эффект на шине SFX.
func play_sfx(name: String, volume_db := 0.0) -> void:
	var stream: AudioStream = _streams.get(name)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = "SFX"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_click() -> void:
	play_sfx("click", -6.0)

## Гул вентиляторов (позиционный, шина SFX) в точке корпуса.
func start_fan_hum(global_pos: Vector3) -> void:
	if _fan_player == null:
		_fan_player = AudioStreamPlayer3D.new()
		_fan_player.bus = "SFX"
		_fan_player.max_distance = 30.0
		_fan_player.unit_size = 6.0
		_fan_player.volume_db = -4.0
		add_child(_fan_player)
	_fan_player.stream = _streams.get("fan")
	_fan_player.global_position = global_pos
	_fan_player.play()

func _stop_fan() -> void:
	if _fan_player != null:
		_fan_player.stop()

func _on_part_installed(_part_id: String) -> void:
	# Только «щелчок» установки; «дзынь»-beep — только при включении в финале (post_overlay).
	play_sfx("snap")

func _on_power_on() -> void:
	play_sfx("power", 2.0)  # звук включения (только после полной сборки)
	start_fan_hum(Vector3(14.0, 10.0, 20.0))  # корпус на полу

func _on_power_off() -> void:
	_stop_fan()

func _start_ambience() -> void:
	var stream: AudioStream = _streams.get("ambient")
	if stream == null:
		return
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.stream = stream
	_ambience_player.bus = "Music"  # эмбиент — как «музыка»: тихо и фоном
	_ambience_player.volume_db = -14.0
	add_child(_ambience_player)
	_ambience_player.play()

# --- загрузка пользовательских файлов или генерация плейсхолдеров ---

func _load_or_make(name: String) -> AudioStream:
	for ext in ["wav", "ogg", "mp3"]:
		var path := "%s/%s.%s" % [AUDIO_DIR, name, ext]
		if ResourceLoader.exists(path):
			return load(path)
	match name:
		"click": return _tone(1800.0, 0.035, 0.5, 0.0)
		"snap": return _thump(150.0, 0.14, 0.9)
		"power": return _chime([660.0, 990.0], 0.16, 0.35)
		"error": return _buzz(190.0, 0.09, 2, 0.45)
		"success": return _chime([523.0, 659.0, 784.0, 1047.0], 0.55, 0.5)
		"ambient": return _noise_loop(0.5, 220.0, -20.0)
		"fan": return _noise_loop(2.5, 90.0, -14.0)
	return null

## Короткий тон (синус) с экспоненциальным затуханием.
func _tone(freq: float, dur: float, amp: float, _attack := 0.0) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 18.0)
		var s := int(sin(TAU * freq * t) * 30000.0 * amp * env)
		data[i * 2] = s & 0xff
		data[i * 2 + 1] = (s >> 8) & 0xff
	return _wav(data, false)

## Низкий «удар» (thump): затухающий низ + короткий щелчок в начале.
func _thump(freq: float, dur: float, amp: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 22.0)
		var s := sin(TAU * freq * t) * 0.85 + sin(TAU * freq * 3.0 * t) * 0.15
		var click := (1.0 if t < 0.006 else 0.0) * 0.6
		data[i * 2] = int(s * 30000.0 * amp * env + click * 12000.0) & 0xff
		data[i * 2 + 1] = (int(s * 30000.0 * amp * env + click * 12000.0) >> 8) & 0xff
	return _wav(data, false)

## Последовательность нот (колокольчик).
func _chime(freqs: Array, dur: float, amp: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var note_dur := dur / float(freqs.size())
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var note_idx := clampi(int(t / note_dur), 0, freqs.size() - 1)
		var local_t := t - float(note_idx) * note_dur
		var env := exp(-local_t * 7.0)
		var s := sin(TAU * float(freqs[note_idx]) * t) * env
		data[i * 2] = int(s * 30000.0 * amp) & 0xff
		data[i * 2 + 1] = (int(s * 30000.0 * amp) >> 8) & 0xff
	return _wav(data, false)

## Двойной низкий «гудок» ошибки.
func _buzz(freq: float, note_dur: float, count: int, amp: float) -> AudioStreamWAV:
	var gap := note_dur * 0.6
	var dur := note_dur * count + gap * (count - 1)
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var slot := t / (note_dur + gap)
		var idx := int(slot)
		var local_t := t - idx * (note_dur + gap)
		var on := idx < count and local_t < note_dur
		var s := 0.0
		if on:
			var env := minf(local_t / 0.008, 1.0) * minf((note_dur - local_t) / 0.02, 1.0)
			s = sin(TAU * freq * t) * env
		data[i * 2] = int(s * 30000.0 * amp) & 0xff
		data[i * 2 + 1] = (int(s * 30000.0 * amp) >> 8) & 0xff
	return _wav(data, false)

## Зацикленный «цветной шум» через однополосный фильтр (эмбиент/гул вентилятора).
func _noise_loop(dur: float, cutoff_hz: float, volume_db: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var amp := pow(10.0, volume_db / 20.0)
	var rc := 1.0 / (TAU * cutoff_hz)
	var dt := 1.0 / SAMPLE_RATE
	var alpha := dt / (rc + dt)
	var y := 0.0
	for i in n:
		var x := randf_range(-1.0, 1.0)
		y = y + alpha * (x - y)  # однополюсный ФНЧ
		var s := int(y * 30000.0 * amp * 3.0)
		data[i * 2] = s & 0xff
		data[i * 2 + 1] = (s >> 8) & 0xff
	return _wav(data, true)

func _wav(data: PackedByteArray, loop: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = data.size() / 2
	return wav
