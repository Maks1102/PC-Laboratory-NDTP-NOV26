extends Node3D
## Главная сцена M0 — каркас: WorldEnvironment, свет, комната, верстак, лоток,
## корпус, детали, CameraRig (Yaw → Pitch → Camera3D) и UILayer.
## Модели, коллизии и drag & drop появятся в M1 (пп. 2–4 TODO).

func _ready() -> void:
	print("[Main] каркас M0 готов | шаг=", GameState.step().id,
			" | фаза=", GameState.phase, " | started=", GameState.started)
