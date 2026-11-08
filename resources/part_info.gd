class_name PartInfo
extends Resource
## Образовательная карточка детали — порт `EduPart` из src/lib/edu/parts.ts.
## Хранится в .tres (resources/parts/*.tres).

## Ключ детали (PartId из веб-версии): "mobo", "cpu", "cooler", "ram", "ssd", "psu", "gpu", "case".
@export var kind: String = ""
## Полное название («Материнская плата»).
@export var name: String = ""
## Короткое название для интерфейса («Материнка»).
@export var short_name: String = ""
## Подзаголовок-характеристика («основание всего компьютера»).
@export var tagline: String = ""
## HEX-цвет для UI-точек («#16a34a»).
@export var color: String = "#ffffff"
## Эмодзи-иконка.
@export var emoji: String = ""
## Что это? — описание для карточки знаний.
@export var description: String = ""
## Зачем нужна? — второй блок карточки.
@export var why: String = ""
## Интересный факт.
@export var fact: String = ""
## Технические характеристики: массив словарей {label, value}.
@export var specs: Array = []
## Краткий вывод для финального экрана.
@export var one_liner: String = ""
