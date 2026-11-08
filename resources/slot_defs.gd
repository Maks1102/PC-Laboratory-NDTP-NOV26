class_name SlotDefs
extends Resource
## Словари слотов: подписи для UI и соответствие «слот → деталь».
## Порт SLOT_LABELS / SLOT_TO_PART из src/lib/edu/lessons.ts. Хранится в slot_defs.tres.

## slot_id → человеческая подпись слота (6 слотов).
@export var slot_labels: Dictionary = {}
## slot_id → part_id: какой компонент «живёт» в слоте (для карточек при клике на слот).
@export var slot_to_part: Dictionary = {}
