# ПК-Лаборатория (Godot)

Обучающий симулятор сборки ПК на **Godot 4.7**.

8 шагов сборки (мат. плата → процессор → кулер → ОЗУ → M.2 SSD → плата в корпус → БП → видеокарта), двухфазный геймплей `explore → install`, орбитальная камера, карточки знаний. Прогресс не сохраняется (по ТЗ).

## Запуск

Открываем Godot -> Импортируем проект -> F6

## Ключевые решения

| Решение | Выбор |
|---|---|
| Версия | Godot **4.7.2** стабильная |
| Язык | **GDScript** |
| Рендерер | **Forward+** (+ Jolt Physics); десктоп-цель |
| Структура | `scenes/`, `scripts/`, `resources/`, `ui/`, `assets/{models,textures,audio,fonts}`, `tests/` |
| Модели | glTF `.glb` → импорт Godot, лежат в `assets/models/` |
| Локализация | все строки UI через `tr()` |

## Структура

```
scenes/Main.tscn        # каркас: WorldEnvironment, свет, комната, Bench, Tray, Case, Parts, Slots, CameraRig, UILayer → UI
scenes/main.gd          # пикинг (raycast слои 2/3), «клик vs драг» 8 px, перетаскивание, snap + tween, reset,
                        # power_on/off: вентиляторы (rotate_z), LED-эмиссионный пульс, внутренняя подсветка
scripts/camera_rig.gd   # орбита (ЛКМ по пустому), панорама (ПКМ), зум (колесо), clamp pitch/дистанция,
                        # блок ввода при drag, экспоненциальное сглаживание, фокус шага (focus/cam tween)
scripts/part.gd         # класс Part: ссылка на PartInfo, пикер-Area3D (слой 2), «домашняя» трансформация, emission-пульс
scripts/snap_zone.gd    # слот-«паз»: Area3D (слой 3 — активный / слой 4 — неактивный), emission-пульс, snap_position/rotation
scripts/hint_zone.gd    # зоны-подсказки пунктиром (ImmediateMesh, без коллизии, скрываются после установки)
scripts/autoload/
  event_bus.gd          # сигналы: part_installed, step_changed, part_rejected, assembly_completed,
                        # phase_changed, info_opened, library_requested, power_on, power_off
  game_state.gd         # стейт-машина: Phase EXPLORE→SELECT→PLACE→CARD, шаги 0–7, busy 6 с, is_dragging, таймер урока
  audio_manager.gd      # звук: шины SFX/Music, плейсхолдеры-генераторы + подмена файлами из assets/audio/
resources/
  lesson_step.gd        # Resource: шаг урока (порт lessons.ts)
  part_info.gd          # Resource: карточка знаний (порт parts.ts)
  lesson_sequence.gd    # Resource: упорядоченная последовательность шагов
  slot_defs.gd          # Resource: SLOT_LABELS + SLOT_TO_PART (6 слотов)
  lesson_sequence.tres  # 8 шагов (собирается tests/gen_sequence.gd)
  slot_defs.tres
  lessons/step-*.tres   # 8 отдельных шагов — тексты правятся без кода
  parts/*.tres          # 8 карточек деталей
ui/
  theme.tres            # Theme (собрана tests/gen_theme.gd): Noto Sans (кириллица), вариации PrimaryButton/GhostButton/Chip/Card/Toast
  ui_root.tscn/.gd      # корень UI: связывает панель урока, карточку, тост, диалоги, финальные экраны
  lesson_panel.tscn/.gd # «Шаг N/8», заголовок, текст (task→place_task), точки прогресса, Подсказка/Детали/Заново
  part_card.tscn/.gd    # карточка знаний: описание, «зачем», факт, характеристики; «Дальше →» в фазе CARD
  dialog.tscn/.gd       # универсальный диалог (приветствие, поздравление, библиотека)
  toast.tscn/.gd        # тост ошибки (текст wrong_part/wrong_slot из LessonStep)
  library.tscn/.gd      # «Библиотека»: кнопки всех 8 деталей
  completion_screen.tscn/.gd  # экран «Сборка завершена» → «Включить компьютер» / «Собрать заново»
  post_overlay.tscn/.gd       # POST: строки самопроверки, beep (880 Гц, синус в коде), затем поздравление
assets/models/*.glb     # 10 моделей из веб-версии (см. models/glb/README.md)
assets/fonts/           # NotoSans-Regular.ttf / NotoSans-Bold.ttf (OFL, кириллица)
assets/audio/           # сюда кладутся пользовательские звуки (см. assets/audio/README.md); без файлов звучат плейсхолдеры
addons/gdUnit4/         # фреймворк юнит-тестов (плагин, headless через GdUnitCmdTool.gd)
docs/REGRESSION.md      # чек-лист ручной регрессии (п.8 TODO)
.github/workflows/ci.yml # CI: import + все тесты на каждый push
tests/
  test_state_machine.tscn/.gd  # прогон всех 8 шагов, ошибок, drag, reset
  test_interaction.tscn/.gd    # реальные события мыши: клик, drag, возврат на лоток, установка CPU в сокет
  test_ui_flow.tscn/.gd        # E2E UI: приветствие → 8 шагов кнопками UI → completion → POST → поздравление → reset
  ui_shots.tscn/.gd            # снимки экранов UI (card, toast, completion, POST, congrats)
  check_resources.gd           # валидация всех 17 .tres
  gen_sequence.gd              # сборка lesson_sequence.tres из step-*.tres
  gen_theme.gd                 # генератор ui/theme.tres из кода (регистрация вариаций set_type_variation)
  screenshot.tscn/.gd          # скриншоты всех состояний сборки в окно (нужен GPU)
  inspect_models.gd            # отладочный дамп иерархии и габаритов .glb
```

## Стейт-машина (порт simulator.tsx)

```
start() → шаг 0 (EXPLORE, клик по детали → CARD) → next_step()
install-шаги: SELECT (выбор детали) → PLACE (перетаскивание/клик по слоту) → CARD → next_step()
ошибки: wrong_part / wrong_slot → сигнал part_rejected, фаза не меняется
финал: finished=true → assembly_completed (анимация включения)
reset() → полный сброс на шаг 0
```

Сигналы EventBus: `part_installed(part_id)`, `step_changed(step_id)`, `part_rejected(reason)`, `assembly_completed`, `phase_changed(phase)`, `info_opened(part_id)`, `library_requested`, `power_on`, `power_off`.

## Слои физики

| Слой | Значение | Что на нём |
|---|---|---|
| 1 | 1 | Статика: комната, верстак, лоток, корпус (raycasts камеры — маска 1) |
| 2 | 2 | Пикер-области деталей (raycast выбора — маска 2) |
| 3 | 4 | Активный слот текущего шага (raycast drag — маска 4) |
| 4 | 8 | Неактивные слоты (только кликовый raycast, маска 12 = 4+8) |
