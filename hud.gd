extends CanvasLayer

const Progress := preload("res://progress.gd")

# Static so it survives reload_current_scene(): the start menu shows only once.
static var show_start_menu := true

# The game script lives on the root node of main.tscn.
@onready var game: Node2D = get_parent()
@onready var joystick: Control = $Joystick
@onready var score_label: Label = $TopBar/Column/Row/Score
@onready var task_label: Label = $TopBar/Column/Row/Task
@onready var time_label: Label = $TopBar/Column/Row/Time
@onready var cash_label: Label = $TopBar/Column/Row2/Cash
@onready var fuel_bar: ProgressBar = $TopBar/Column/Row2/FuelBar
@onready var menu: Control = $Menu
@onready var title_label: Label = $Menu/Center/Box/Title
@onready var message_label: Label = $Menu/Center/Box/Message
@onready var wallet_label: Label = $Menu/Center/Box/Wallet
@onready var shop: VBoxContainer = $Menu/Center/Box/Shop
@onready var play_button: Button = $Menu/Center/Box/PlayButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	if show_start_menu:
		_open_menu("Last Mile", "Pick up parcels and deliver them before the clock or the fuel runs out.", "Play")
		get_tree().paused = true
	else:
		menu.hide()

func _process(_delta: float) -> void:
	score_label.text = "Deliveries: %d" % game.score
	time_label.text = "Time: %d" % ceili(game.time_left)
	time_label.modulate = Color.TOMATO if game.time_left < 10.0 else Color.WHITE
	task_label.text = "Deliver the parcel" if game.carrying else "Pick up a parcel"
	task_label.modulate = game.DROPOFF_COLOR if game.carrying else game.PICKUP_COLOR
	cash_label.text = "Cash: %d" % Progress.money
	fuel_bar.max_value = game.max_fuel
	fuel_bar.value = game.fuel
	fuel_bar.modulate = Color.TOMATO if game.fuel < game.max_fuel * game.LOW_FUEL else Color.WHITE

	if game.game_over and not menu.visible:
		var summary := "Deliveries: %d      Earned: %d" % [game.score, game.earned]
		_open_menu(game.end_reason, summary, "Play again")

func _open_menu(title: String, message: String, button_text: String) -> void:
	title_label.text = title
	message_label.text = message
	play_button.text = button_text
	_refresh_shop()
	menu.show()
	play_button.grab_focus()  # so Enter or Space also presses it
	joystick.set_process_input(false)
	joystick.release()

# Rebuild the shop rows from the table in progress.gd.
func _refresh_shop() -> void:
	wallet_label.text = "Cash: %d      Best: %d deliveries" % [Progress.money, Progress.best_score]
	for row in shop.get_children():
		row.queue_free()

	for id: String in Progress.UPGRADES:
		var info: Dictionary = Progress.UPGRADES[id]

		var label := Label.new()
		label.text = "%s  %d/%d   %s" % [info["name"], Progress.levels[id], info["max_level"], info["effect"]]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 22)

		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 48)
		button.add_theme_font_size_override("font_size", 22)
		if Progress.is_maxed(id):
			button.text = "Max"
			button.disabled = true
		else:
			button.text = "Buy  %d" % Progress.cost(id)
			button.disabled = not Progress.can_buy(id)
			button.pressed.connect(_on_buy_pressed.bind(id))

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		row.add_child(label)
		row.add_child(button)
		shop.add_child(row)

func _on_buy_pressed(id: String) -> void:
	Progress.buy(id)
	# Deferred so we do not delete a button while it is still handling its click.
	_refresh_shop.call_deferred()

func _on_play_pressed() -> void:
	if game.game_over:
		get_tree().reload_current_scene()
		return
	show_start_menu = false
	game.apply_upgrades()
	get_tree().paused = false
	menu.hide()
	joystick.set_process_input(true)
