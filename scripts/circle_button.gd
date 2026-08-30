class_name CircleButton
extends Control

## Un botón redondo que se dibuja solo y se pulsa tocándolo.
##
## No es un Button de Godot a propósito. El proyecto tiene activado
## emulate_touch_from_mouse para que el mismo código de input sirva en el editor
## y en el teléfono, y mezclar eso con el sistema de foco y ratón de los Control
## es una fuente de rarezas que no compensa por un botón. Además así el botón se
## pulsa exactamente igual que se juega: tocando un círculo.

@export var color: Color = Color("ff5470")
## Amplitud del latido. Lo justo para que el ojo vaya solo, sin distraer.
@export var pulse: float = 0.025

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var factor := 1.0 + pulse * sin(_t * 2.2)
	draw_circle(size * 0.5, _radio() * factor, color)


func contiene(punto: Vector2) -> bool:
	return punto.distance_to(global_position + size * 0.5) <= _radio()


func _radio() -> float:
	return minf(size.x, size.y) * 0.5
