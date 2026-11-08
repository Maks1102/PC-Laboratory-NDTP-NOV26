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
scenes/Main.tscn        # каркас: WorldEnvironment, свет, комната, Bench, Tray, Case, Parts, CameraRig, UILayer
scenes/main.gd
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
  check_resources.gd           # валидация всех 17 .tres
  gen_sequence.gd              # сборка lesson_sequence.tres из step-*.tres
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

## Дальше по TODO

- **M1** (пп. 2–4): модели в сцену, коллизии, камера (CameraRig), drag & drop со слотами-«пазами»
- **M2** (пп. 5–6): UI-панели, диалоги, спецанимации, финал
- **M3** (пп. 7–8): звук, gdUnit4, CI
- **M4** (п. 9): экспорт Web/десктоп
