class_name LessonSequence
extends Resource
## Последовательность шагов урока (порядок 0–7) — хранится в lesson_sequence.tres.
## Порядок шагов задаётся здесь, без правки кода.

@export var steps: Array[LessonStep] = []
