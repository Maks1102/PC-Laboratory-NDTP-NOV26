extends PanelContainer
## Всплывающее уведомление об ошибке (п.5 TODO): текст из wrong_part/wrong_slot
## или общий отказ стейт-машины. Само скрывается через 5 секунд.

const AUTO_HIDE_SEC := 5.0

@onready var _message: Label = $Row/Message

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	$Row/CloseButton.pressed.connect(func() -> void: visible = false)
	EventBus.part_rejected.connect(_on_rejected)

func _on_rejected(reason: String) -> void:
	_message.text = reason
	visible = true
	var timer := get_tree().create_timer(AUTO_HIDE_SEC)
	timer.timeout.connect(func() -> void: visible = false)
