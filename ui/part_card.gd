extends PanelContainer
## Карточка знаний (п.5 TODO): название, описание, «зачем», факт, характеристики.
## Открывается по клику на деталь/слот (EventBus.info_opened). В фазе CARD
## основная кнопка — «Дальше →» (переход к следующему шагу урока).

const PART_IDS := ["mobo", "cpu", "cooler", "ram", "ssd", "psu", "gpu", "case"]

var _infos: Dictionary = {}
var _current_id := ""

@onready var _stripe: Panel = $Margin/VBox/Header/Stripe
@onready var _name: Label = $Margin/VBox/Header/NameBox/NameLabel
@onready var _tagline: Label = $Margin/VBox/Header/NameBox/TaglineLabel
@onready var _description: Label = $Margin/VBox/Scroll/Body/Description
@onready var _why: Label = $Margin/VBox/Scroll/Body/Why
@onready var _fact: Label = $Margin/VBox/Scroll/Body/Fact
@onready var _specs: GridContainer = $Margin/VBox/Scroll/Body/SpecsGrid
@onready var _action: Button = $Margin/VBox/ActionButton

func _ready() -> void:
	theme = load("res://ui/theme.tres")
	for id in PART_IDS:
		var res := load("res://resources/parts/%s.tres" % id)
		if res != null:
			_infos[id] = res
	$Margin/VBox/Header/CloseButton.pressed.connect(hide)
	_action.pressed.connect(_on_action)
	EventBus.info_opened.connect(_on_info_opened)
	EventBus.phase_changed.connect(func(_p: int) -> void: _refresh_action())

func _on_info_opened(part_id: String) -> void:
	var info: PartInfo = _infos.get(part_id)
	if info == null:
		return
	_current_id = part_id
	_name.text = info.name
	_tagline.text = info.tagline
	_description.text = info.description
	_why.text = info.why
	_fact.text = info.fact
	var stripe_color := Color.from_string(info.color, Color(0.086, 0.639, 0.29))
	var sb := StyleBoxFlat.new()
	sb.bg_color = stripe_color
	sb.corner_radius_top_left = 5
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_top_right = 5
	sb.corner_radius_bottom_right = 5
	_stripe.add_theme_stylebox_override("panel", sb)
	_fill_specs(info.specs)
	_refresh_action()
	visible = true

func _fill_specs(specs: Array) -> void:
	for child in _specs.get_children():
		child.queue_free()
	for entry in specs:
		var label := Label.new()
		label.text = str(entry.get("label", ""))
		label.add_theme_color_override("font_color", Color(0.45, 0.48, 0.56))
		_specs.add_child(label)
		var value := Label.new()
		value.text = str(entry.get("value", ""))
		value.add_theme_color_override("font_color", Color(0.15, 0.18, 0.26))
		_specs.add_child(value)

func _refresh_action() -> void:
	var in_card := GameState.phase == GameState.Phase.CARD and not GameState.finished
	_action.text = tr("Дальше →") if in_card else tr("Закрыть")

func _on_action() -> void:
	if GameState.phase == GameState.Phase.CARD and not GameState.finished:
		hide()
		GameState.next_step()
	else:
		hide()
