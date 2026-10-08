extends Node2D

const Progress := preload("res://progress.gd")

const ROUND_TIME := 60.0   # seconds on the clock at the start
const TIME_BONUS := 8.0    # seconds added for each delivery
const MIN_DISTANCE := 400.0  # new markers spawn at least this far from the rider
const DELIVERY_PAY := 10   # cash earned for each delivery

const BASE_SPEED := 300.0
const BASE_FUEL := 100.0
const FUEL_PER_PIXEL := BASE_FUEL / 7500.0  # a basic tank lasts 7500 px of driving
const LOW_FUEL := 0.35     # below this share of the tank, the fuel arrow appears

const PICKUP_COLOR := Color.YELLOW
const DROPOFF_COLOR := Color.LIME_GREEN

@onready var city: TileMapLayer = $City
@onready var player: CharacterBody2D = $Player
@onready var marker: Area2D = $Marker
@onready var fuel_can: Area2D = $FuelCan
@onready var arrow: Polygon2D = $Arrow
@onready var fuel_arrow: Polygon2D = $FuelArrow

# The HUD reads these every frame to draw the score, clock, fuel and menus.
var score := 0
var earned := 0            # cash earned this round
var time_left := ROUND_TIME
var fuel := BASE_FUEL
var max_fuel := BASE_FUEL
var carrying := false
var game_over := false
var end_reason := ""

func _ready() -> void:
	Progress.load_progress()
	apply_upgrades()
	marker.reached.connect(_on_marker_reached)
	fuel_can.reached.connect(_on_fuel_can_reached)
	_move_to_road(marker)
	_move_to_road(fuel_can)

# Called at the start of a round, and again by the HUD when Play is pressed,
# so upgrades bought on the start menu count straight away.
func apply_upgrades() -> void:
	player.speed = BASE_SPEED * Progress.speed_multiplier()
	max_fuel = BASE_FUEL * Progress.fuel_multiplier()
	fuel = max_fuel
	time_left = ROUND_TIME + Progress.bonus_time()

func _process(delta: float) -> void:
	if game_over:
		return

	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_end_round("Time up!")
		return

	# Fuel burns with distance driven, so standing still is free.
	fuel -= player.velocity.length() * delta * FUEL_PER_PIXEL
	if fuel <= 0.0:
		fuel = 0.0
		_end_round("Out of fuel!")
		return

	_point_arrow(arrow, marker)
	fuel_arrow.visible = fuel < max_fuel * LOW_FUEL
	_point_arrow(fuel_arrow, fuel_can)

# Keep an arrow beside the rider, pointing at a target.
func _point_arrow(pointer: Polygon2D, target: Node2D) -> void:
	var direction := player.position.direction_to(target.position)
	pointer.position = player.position + direction * 48.0
	pointer.rotation = direction.angle()

func _on_marker_reached() -> void:
	if game_over:
		return
	if carrying:
		score += 1
		earned += DELIVERY_PAY
		Progress.money += DELIVERY_PAY
		time_left += TIME_BONUS
	carrying = not carrying
	marker.color = DROPOFF_COLOR if carrying else PICKUP_COLOR
	arrow.color = marker.color
	# Deferred because we are inside a physics callback.
	_move_to_road.call_deferred(marker)

func _on_fuel_can_reached() -> void:
	if game_over:
		return
	fuel = max_fuel
	_move_to_road.call_deferred(fuel_can)

func _move_to_road(node: Node2D) -> void:
	var spot: Vector2 = city.random_road_position()
	while spot.distance_to(player.position) < MIN_DISTANCE:
		spot = city.random_road_position()
	node.position = spot

func _end_round(reason: String) -> void:
	game_over = true
	end_reason = reason
	Progress.best_score = maxi(Progress.best_score, score)
	Progress.save_progress()
	player.set_physics_process(false)
	arrow.hide()
	fuel_arrow.hide()
	marker.hide()
	fuel_can.hide()
