extends Area2D

# Fired when the car runs into the rider.
signal hit_rider

const ROAD_TILE := Vector2i(0, 0)  # the road's position in tiles.png
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

@export var speed := 140.0
@export var color := Color.CRIMSON

var city: TileMapLayer            # set by traffic.gd when the car is spawned
var cell: Vector2i                # the road tile the car is driving towards
var direction := Vector2i.RIGHT

func _ready() -> void:
	add_to_group("cars")
	body_entered.connect(_on_body_entered)
	_choose_next_cell()

func _physics_process(delta: float) -> void:
	var target := city.map_to_local(cell)
	position = position.move_toward(target, speed * delta)
	if position.is_equal_approx(target):
		_choose_next_cell()

# At each tile, look at the neighbouring roads and pick where to go next.
func _choose_next_cell() -> void:
	var options: Array[Vector2i] = []
	for d in DIRECTIONS:
		if d != -direction and _is_road(cell + d):
			options.append(d)

	if options.is_empty():
		direction = -direction          # dead end: turn around
	elif not (direction in options and randf() < 0.7):
		direction = options.pick_random()  # otherwise keep going straight

	cell += direction
	rotation = Vector2(direction).angle()

func _is_road(c: Vector2i) -> bool:
	return city.get_cell_atlas_coords(c) == ROAD_TILE

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		hit_rider.emit()

func _draw() -> void:
	draw_rect(Rect2(-20, -12, 40, 24), color)
	draw_rect(Rect2(4, -9, 8, 18), Color(0.75, 0.9, 1.0))   # windscreen
	draw_rect(Rect2(-20, -12, 40, 24), Color.BLACK, false, 2.0)
