extends Node2D

const CAR_SCENE := preload("res://car.tscn")
const COLORS: Array[Color] = [Color.CRIMSON, Color.ROYAL_BLUE, Color.ORANGE, Color.WHITE_SMOKE]

@export var car_count := 6
@export var time_penalty := 5.0   # seconds lost when a car hits the rider
@export var safe_distance := 300.0  # cars never spawn closer than this to the rider

# The game script lives on the root node; the city and rider are our siblings.
@onready var game: Node2D = get_parent()
@onready var city: TileMapLayer = $"../City"
@onready var player: CharacterBody2D = $"../Player"

func _ready() -> void:
	for i in car_count:
		_spawn_car(i)

func _process(_delta: float) -> void:
	if game.game_over:
		get_tree().call_group("cars", "set_physics_process", false)

func _spawn_car(index: int) -> void:
	var spot: Vector2 = city.random_road_position()
	while spot.distance_to(player.position) < safe_distance:
		spot = city.random_road_position()

	var car := CAR_SCENE.instantiate()
	car.city = city
	car.position = spot
	car.cell = city.local_to_map(spot)
	car.color = COLORS[index % COLORS.size()]
	car.hit_rider.connect(_on_car_hit_rider)
	add_child(car)

func _on_car_hit_rider() -> void:
	if game.game_over:
		return
	game.time_left -= time_penalty
	# Flash the rider red so the hit is obvious.
	player.modulate = Color.RED
	create_tween().tween_property(player, "modulate", Color.WHITE, 0.4)
