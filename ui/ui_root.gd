extends Control
## Корень UI (п.5 TODO): собирает панель урока, карточку, тост, диалоги,
## экран завершения и POST-сцену; связывает их между собой и с GameState.

@onready var _dialog: Control = $Dialog
@onready var _completion: Control = $CompletionScreen
@onready var _post: Control = $PostOverlay
@onready var _library: Control = $Library

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Звук клика на всех кнопках, которые уже есть в дереве (динамические — в dialog.gd).
	_connect_click_sounds(self)
	# Финал: «Сборка завершена» (с небольшой задержкой, чтобы доиграл твин snap).
	EventBus.assembly_completed.connect(func() -> void:
		get_tree().create_timer(0.8).timeout.connect(_completion.show_screen))
	# Экран завершения → питание → POST → финальное поздравление.
	_completion.power_pressed.connect(func() -> void:
		EventBus.power_on.emit()
		_post.run())
	_completion.reset_pressed.connect(GameState.reset)
	_post.boot_finished.connect(_show_congratulations)
	# Полный сброс прячет все оверлеи.
	EventBus.step_changed.connect(func(step_id: String) -> void:
		if step_id == "step-mobo" and GameState.installed.is_empty():
			_completion.visible = false
			_post.visible = false
			_library.visible = false)
	# Приветствие при первом запуске.
	_dialog.show_dialog(
		tr("Привет! Я — твой наставник по сборке ПК"),
		tr("Сейчас ты соберёшь настоящий компьютер с нуля: от материнской платы до видеокарты.\n\nНа каждом шаге я буду подсказывать, что делать. Детали выбираются кликом, ставятся перетаскиванием к подсвеченному пазу. Если ошибёшься — ничего страшного: деталь вернётся на лоток, а я подскажу, что не так.\n\nПоехали!"),
		[{id = "start", text = tr("Начать сборку"), primary = true}])

func _connect_click_sounds(node: Node) -> void:
	if node is Button:
		node.pressed.connect(AudioManager.play_click)
	for child in node.get_children():
		_connect_click_sounds(child)

func _show_congratulations() -> void:
	var elapsed := int(GameState.elapsed_seconds())
	var minutes := elapsed / 60
	var seconds := elapsed % 60
	var time_str := tr("%d мин %d с") % [minutes, seconds] if minutes > 0 else tr("%d с") % seconds
	_dialog.show_dialog(
		tr("Поздравляем!"),
		tr("Ты собрал(а) компьютер с нуля за %s. Установлено деталей: %d из 7.\n\nТеперь ты знаешь, чем процессор отличается от видеокарты — и зачем нужен кулер.") % [time_str, GameState.installed.size()],
		[
			{id = "again", text = tr("Собрать заново"), primary = true},
			{id = "look", text = tr("Осмотреть компьютер")},
		])
	if not _dialog.button_pressed.is_connected(_on_congrats_button):
		_dialog.button_pressed.connect(_on_congrats_button)

func _on_congrats_button(id: String) -> void:
	match id:
		"again":
			GameState.reset()
		_:
			pass
