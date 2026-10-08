extends RefCounted

# Everything that survives between rounds and between launches: cash, upgrade
# levels and best score. It is all static, so any script can use it through
#   const Progress := preload("res://progress.gd")
# without needing a node in the scene.

const SAVE_PATH := "user://save.cfg"

# The shop is built from this table. Add an entry here to add an upgrade.
const UPGRADES := {
	"engine": {"name": "Engine", "effect": "+12% speed", "base_cost": 30, "max_level": 5},
	"tank": {"name": "Fuel tank", "effect": "+20% fuel", "base_cost": 20, "max_level": 5},
	"clock": {"name": "Head start", "effect": "+5s on the clock", "base_cost": 25, "max_level": 5},
}

static var money := 0
static var best_score := 0
static var levels := {"engine": 0, "tank": 0, "clock": 0}
static var _loaded := false

static func load_progress() -> void:
	if _loaded:
		return
	_loaded = true
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return  # no save yet: keep the defaults
	money = file.get_value("player", "money", 0)
	best_score = file.get_value("player", "best_score", 0)
	for id in UPGRADES:
		levels[id] = file.get_value("upgrades", id, 0)

static func save_progress() -> void:
	var file := ConfigFile.new()
	file.set_value("player", "money", money)
	file.set_value("player", "best_score", best_score)
	for id in UPGRADES:
		file.set_value("upgrades", id, levels[id])
	file.save(SAVE_PATH)

# Each level costs more than the last: 30, 60, 90...
static func cost(id: String) -> int:
	return UPGRADES[id]["base_cost"] * (levels[id] + 1)

static func is_maxed(id: String) -> bool:
	return levels[id] >= UPGRADES[id]["max_level"]

static func can_buy(id: String) -> bool:
	return not is_maxed(id) and money >= cost(id)

static func buy(id: String) -> void:
	if not can_buy(id):
		return
	money -= cost(id)
	levels[id] += 1
	save_progress()

# What the upgrades actually do. game.gd reads these at the start of a round.
static func speed_multiplier() -> float:
	return 1.0 + 0.12 * levels["engine"]

static func fuel_multiplier() -> float:
	return 1.0 + 0.2 * levels["tank"]

static func bonus_time() -> float:
	return 5.0 * levels["clock"]
