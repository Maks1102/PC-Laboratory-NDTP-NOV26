# ПК-Лаборатория (Godot)

Обучающий симулятор сборки ПК — порт WebGL-версии ([pc-anatomy-3d](../pc-anatomy-3d), Next.js 16 + Three.js) на **Godot 4.7**.

8 шагов сборки (мат. плата → процессор → кулер → ОЗУ → M.2 SSD → плата в корпус → БП → видеокарта), двухфазный геймплей `explore → install`, орбитальная камера, карточки знаний. Прогресс не сохраняется (по ТЗ).

## Запуск

```powershell
# редактор
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64.exe" --path .

# headless-импорт (нужен после первого клонирования)
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --import

# тесты
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://tests/test_state_machine.tscn   # стейт-машина
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/check_resources.gd  # все .tres
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://tests/test_interaction.tscn     # клик/драг через симуляцию мыши

# скриншоты всех 10 состояний сборки (нужен дисплей/GPU)
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64.exe" --path . res://tests/screenshot.tscn   # → tests/screenshots/*.png
```

## Ключевые решения (п.0 TODO)

| Решение | Выбор |
|---|---|
| Версия | Godot **4.7.2** стабильная |
| Язык | **GDScript** (веб-экспорт P0 — C# не экспортируется в Web) |
| Рендерер | **Forward+** (+ Jolt Physics) — выбрано владельцем проекта; десктоп-цель |
| Структура | `scenes/`, `scripts/`, `resources/`, `ui/`, `assets/{models,textures,audio,fonts}`, `tests/` |
| Модели | glTF `.glb` → импорт Godot, лежат в `assets/models/` (исходные FBX — в `models/fbx/`) |
| Локализация | все строки UI через `tr()`, пока только русский |

## Структура

```
scenes/Main.tscn        # каркас: WorldEnvironment, свет, комната, Bench, Tray, Case, Parts, Slots, CameraRig, UILayer
scenes/main.gd          # пикинг (raycast слои 2/3), «клик vs драг» 8 px, перетаскивание, snap + tween, reset
scripts/camera_rig.gd   # орбита (ЛКМ по пустому), панорама (ПКМ), зум (колесо), clamp pitch/дистанция,
                        # блок ввода при drag, экспоненциальное сглаживание, фокус шага (focus/cam tween)
scripts/part.gd         # класс Part: ссылка на PartInfo, пикер-Area3D (слой 2), «домашняя» трансформация, emission-пульс
scripts/snap_zone.gd    # слот-«паз»: Area3D (слой 3 — активный / слой 4 — неактивный), emission-пульс, snap_position/rotation
scripts/hint_zone.gd    # зоны-подсказки пунктиром (ImmediateMesh, без коллизии, скрываются после установки)
scripts/autoload/
  event_bus.gd          # сигналы: part_installed, step_changed, part_rejected, assembly_completed
  game_state.gd         # стейт-машина: Phase EXPLORE→SELECT→PLACE→CARD, шаги 0–7, busy 6 с, is_dragging
resources/
  lesson_step.gd        # Resource: шаг урока (порт lessons.ts)
  part_info.gd          # Resource: карточка знаний (порт parts.ts)
  lesson_sequence.gd    # Resource: упорядоченная последовательность шагов
  slot_defs.gd          # Resource: SLOT_LABELS + SLOT_TO_PART (6 слотов)
  lesson_sequence.tres  # 8 шагов (собирается tests/gen_sequence.gd)
  slot_defs.tres
  lessons/step-*.tres   # 8 отдельных шагов — тексты правятся без кода
  parts/*.tres          # 8 карточек деталей
tests/
  test_state_machine.tscn/.gd  # прогон всех 8 шагов, ошибок, drag, reset
  test_interaction.tscn/.gd    # реальные события мыши: клик, drag, возврат на лоток, установка CPU в сокет
  check_resources.gd           # валидация всех 17 .tres
  gen_sequence.gd              # сборка lesson_sequence.tres из step-*.tres
  screenshot.tscn/.gd          # скриншоты всех состояний сборки в окно (нужен GPU)
  inspect_models.gd            # отладочный дамп иерархии и габаритов .glb
assets/models/*.glb     # 10 моделей из веб-версии (см. models/glb/README.md)
```

## Стейт-машина (порт simulator.tsx)

```
start() → шаг 0 (EXPLORE, клик по детали → CARD) → next_step()
install-шаги: SELECT (выбор детали) → PLACE (перетаскивание/клик по слоту) → CARD → next_step()
ошибки: wrong_part / wrong_slot → сигнал part_rejected, фаза не меняется
финал: finished=true → assembly_completed (анимация включения — M2)
reset() → полный сброс на шаг 0
```

Сигналы EventBus: `part_installed(part_id)`, `step_changed(step_id)`, `part_rejected(reason)`, `assembly_completed`.

## Слои физики

| Слой | Значение | Что на нём |
|---|---|---|
| 1 | 1 | Статика: комната, верстак, лоток, корпус (raycasts камеры — маска 1) |
| 2 | 2 | Пикер-области деталей (raycast выбора — маска 2) |
| 3 | 4 | Активный слот текущего шага (raycast drag — маска 4) |
| 4 | 8 | Неактивные слоты (только кликовый raycast, маска 12 = 4+8) |

## Отклонения от WEB-версии / TODO (осознанные)

- **Детали — не наследники `Part.tscn`**, а узлы-`Part` инлайново в `Main.tscn` со скриптом `part.gd` (проще для ручной правки раскладки; пикер-область генерируется автоматически по габаритам .glb).
- **Перетаскивание — по лучу камеры** (деталь едет за курсором на фиксированном удалении и «падает» на подсвеченный слот), а не по горизонтальной плоскости: иначе PSU в отсеке у дна корпуса было бы невозможно дотянуть.
- **Слои вместо `intersect_ray`-фильтра**: неактивные зоны невидимы для drag-лучей (drag бьёт только активный слот).
- **`Part`-ареа и все зоны** создаются/настраиваются кодом (`part.gd::_add_default_area`, `snap_zone.gd::_ready`) — сцена остаётся читаемой.
- **Лоток и комната — из примитивов**, отдельного `.glb` под лоток в веб-версии не было.
- **`focus`/`cam` в `resources/lessons/*.tres` переписаны** под новую раскладку сцены (веб-координаты не соответствуют моделям 1:1).
- **GPU ставится «вертикально»** (длина вдоль вертикали, вентиляторы к стеклу) — требование геометрии слота PCIe в модели: слот параллелен задней кромке.

## Дальше по TODO

- **M2** (пп. 5–6): UI-панели, диалоги, спецанимации, финал
- **M3** (пп. 7–8): звук, gdUnit4, CI
- **M4** (п. 9): экспорт Web/десктоп
