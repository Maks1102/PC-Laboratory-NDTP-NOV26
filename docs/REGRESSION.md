# Чек-лист ручной регрессии (п.8 TODO, M3)

Прогон перед релизом / после существенных правок геймплея.
Автоматизированные пункты отмечены ✔ и покрываются автотестами (см. ниже «Как прогонять»).

## Обязательные сценарии

- [ ] **Камера не реагирует во время драга; после отпускания работают орбита (ЛКМ), панорама (ПКМ), зум (колесо).**
      Как: взять деталь, попробовать вращать камеру — не вращается; отпустить; покрутить ЛКМ/ПКМ/колесом — всё работает.
      Авточастично: `test_interaction.tscn` (drag CPU в сокет), камера проверяется визуально.
- [ ] **Все 8 шагов проходят подряд с чистого старта** (Материнская плата → … → Видеокарта → включение).
      Авто ✔: `test_ui_flow.tscn` (E2E через кнопки UI) + `screenshot.tscn` (8 шагов со скриншотами).
- [ ] **Неверная деталь возвращается на лоток, показана подсказка (`wrong_part`).**
      Авто ✔: `test_interaction.tscn` (drag неверной детали → возврат + `part_rejected`), тост проверен визуально (`tests/screenshots/ui-toast.png`).
- [ ] **Пунктирные зоны-подсказки исчезают после шага 5 (плата в корпусе) и шага 6 (БП).**
      Авто ✔: `tests/gdunit/test_hint_zone.gd` (скрытие по `part_installed` для mobo/psu; игнорируются чужие детали).
- [ ] **В финальной сборке ни одна деталь не пересекается с корпусом/верстаком.**
      Ручной: осмотреть корпус на скриншотах `tests/screenshots/09-final.png` / `10-done.png`;
      опционально — облёт камеры в игре после завершения («Осмотреть компьютер» в финальном диалоге).

## Быстрая проверка экранов (папка tests/screenshots/)

- [ ] `01-mobo`…`08-gpu`: подсветка нужной детали/слота, пунктирные зоны видны до установки.
- [ ] `ui-card-mobo`: карточка знаний при шаге 1.
- [ ] `ui-toast`: тост ошибки `wrong_part`.
- [ ] `ui-completion`: экран «Сборка завершена».
- [ ] `ui-post`: POST-экран включения.
- [ ] `ui-congrats`: финальное поздравление + вентиляторы/LED включены (корпус светится зелёным).

## Как прогонять

```powershell
# headless-импорт (после первого клонирования или изменения ассетов)
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --import

# автотесты (всё должно быть PASS)
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/check_resources.gd
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://tests/test_state_machine.tscn
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://tests/test_interaction.tscn
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://tests/test_ui_flow.tscn
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/gdunit --ignoreHeadlessMode

# скриншоты (нужен GPU)
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64.exe" --path . res://tests/screenshot.tscn
& "F:\Programms\Godot\Godot_v4.7.2-stable_win64.exe" --path . res://tests/ui_shots.tscn
```

## Баг-репорт

Записать: шаг и фазу (SELECT/PLACE), что нажато, что ожидалось (текст из LessonStep), номер скриншота.
