class_name LessonStep
extends Resource
## Шаг урока — прямой порт `LessonStep` из веб-версии (src/lib/edu/lessons.ts).
## Хранится в .tres: правка текстов подсказок без изменения кода.

enum Kind { EXPLORE, INSTALL }

## Идентификатор шага, как в веб-версии: "step-mobo", "step-cpu", …
@export var id: String = ""
## Фаза шага: EXPLORE — осмотр детали, INSTALL — установка в слот.
@export var kind: Kind = Kind.EXPLORE
## Какая деталь — цель шага (part_id из PartInfo: "mobo", "cpu", …).
@export var part_id: String = ""
## Слот-«паз» для установки ("" — у шага осмотра слота нет).
@export var slot_id: String = ""
## Альтернативные кликабельные цели в фазе установки (например, кулер ставится кликом на процессор).
@export var alt_targets: PackedStringArray = PackedStringArray()
## Заголовок шага.
@export var title: String = ""
## Задание в фазе выбора детали.
@export var task: String = ""
## Задание в фазе установки в слот (появляется после взятия детали).
@export var place_task: String = ""
## Текст ошибки: выбрана не та деталь.
@export var wrong_part: String = ""
## Текст ошибки: деталь тянется не в тот слот.
@export var wrong_slot: String = ""
## Дополнительная подсказка (кнопка «Подсказка»).
@export var extra_hint: String = ""
## Точка, к которой плавно подъезжает взгляд (цель орбиты камеры).
@export var focus: Vector3 = Vector3.ZERO
## Куда дополнительно перемещается сама камера (нужно для работы с корпусом на полу).
## Vector3.ZERO — камера не перемещается, только фокус.
@export var cam: Vector3 = Vector3.ZERO
