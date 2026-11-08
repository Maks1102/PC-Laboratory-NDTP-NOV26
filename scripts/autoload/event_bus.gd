extends Node
## Автолоад EventBus — глобальная шина сигналов (аналог колбэков сцены в веб-версии).
## Подключается к сигналам: part_installed, step_changed, part_rejected, assembly_completed.

## Деталь успешно установлена в слот (part_id: String).
signal part_installed(part_id: String)
## Текущий шаг урока изменился (step_id: String, например "step-cpu").
signal step_changed(step_id: String)
## Отказ: неверная деталь или слот (reason: String — текст подсказки из LessonStep).
signal part_rejected(reason: String)
## Сборка завершена — финальная анимация включения.
signal assembly_completed
