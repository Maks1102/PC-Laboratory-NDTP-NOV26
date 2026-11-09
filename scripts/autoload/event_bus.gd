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
## Фаза стейт-машины изменилась (GameState.Phase: EXPLORE=0, SELECT=1, PLACE=2, CARD=3).
signal phase_changed(phase: int)
## Запрошена карточка знаний (part_id: String; "" игнорировать нельзя — всегда непустой).
signal info_opened(part_id: String)
## Запрошена «Библиотека» деталей.
signal library_requested
## Питание подано (кнопка «Включить компьютер» → POST, вентиляторы, LED).
signal power_on
## Питание снято (reset / «Собрать заново») — вентиляторы и LED гаснут.
signal power_off
