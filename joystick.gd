extends Control

# A floating on-screen joystick. Touch anywhere on the left half of the screen
# and drag: it presses the same move_* actions the keyboard uses, so player.gd
# does not need to know touch exists.

const RADIUS := 80.0      # how far the knob can travel from the base
const KNOB_RADIUS := 34.0

var _touch_index := -1    # which finger is on the stick (-1 = none)
var _base := Vector2.ZERO
var _knob := Vector2.ZERO

func _ready() -> void:
	# Lets you test the joystick with the mouse on desktop.
	Input.emulate_touch_from_mouse = true

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and event.position.x < size.x / 2.0:
			_touch_index = event.index
			_base = event.position
			_knob = _base
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_knob = _base + (event.position - _base).limit_length(RADIUS)
		_apply((_knob - _base) / RADIUS)
		queue_redraw()

# Let go of the stick and stop the rider.
func release() -> void:
	_touch_index = -1
	_apply(Vector2.ZERO)
	queue_redraw()

func _apply(v: Vector2) -> void:
	_set_action("move_right", v.x)
	_set_action("move_left", -v.x)
	_set_action("move_down", v.y)
	_set_action("move_up", -v.y)

func _set_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_base, RADIUS, Color(1, 1, 1, 0.15))
	draw_arc(_base, RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 3.0)
	draw_circle(_knob, KNOB_RADIUS, Color(1, 1, 1, 0.6))
