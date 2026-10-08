extends Area2D

# Fired when the rider drives onto the marker.
signal reached

@export var color := Color.YELLOW:
	set(value):
		color = value
		queue_redraw()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		reached.emit()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, color)
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 32, Color.BLACK, 3.0)
