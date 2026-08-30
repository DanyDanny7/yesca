class_name Dot
extends Node2D

## Un punto del campo.
##
## Se dibuja a sí mismo con _draw(): para un prototipo de formas geométricas no
## hace falta ni sprite ni escena propia, se instancia con Dot.new().

const COLOR := Color("e8e8f0")

@export var radius: float = 9.0

var velocity: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	# Todo movimiento va multiplicado por delta. Si no, el juego corre a
	# distinta velocidad en cada dispositivo según sus FPS.
	position += velocity * delta
	_bounce_on_edges()
	# Ojo: no hace falta queue_redraw(). _draw() dibuja en espacio LOCAL, y lo
	# que cambia es la transform del nodo. Redibujar cada frame sería trabajo
	# tirado a la basura.


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, COLOR)


func _bounce_on_edges() -> void:
	var rect := get_viewport_rect()
	# Se comprueba también el signo de la velocidad: sin eso, un punto que
	# aparece fuera del borde queda atrapado invirtiéndose cada frame.
	if position.x < radius and velocity.x < 0.0:
		velocity.x = -velocity.x
	elif position.x > rect.size.x - radius and velocity.x > 0.0:
		velocity.x = -velocity.x
	if position.y < radius and velocity.y < 0.0:
		velocity.y = -velocity.y
	elif position.y > rect.size.y - radius and velocity.y > 0.0:
		velocity.y = -velocity.y
