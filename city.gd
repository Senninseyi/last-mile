extends TileMapLayer

# Each character is one 64px tile. Edit the rows to redraw the city.
#   # = road    . = grass    B = building (solid)
const LAYOUT: Array[String] = [
	"BBBBBBBBBBBBBBBBBBBBBBBB",
	"B######################B",
	"B#......#......#......#B",
	"B#.BBBB.#.BBBB.#.BBBB.#B",
	"B#.BBBB.#.BBBB.#.BBBB.#B",
	"B#.BBBB.#.BBBB.#.BBBB.#B",
	"B#......#......#......#B",
	"B######################B",
	"B#......#......#......#B",
	"B#.BBBB.#.BBBB.#.BBBB.#B",
	"B#.BBBB.#.BBBB.#.BBBB.#B",
	"B#.BBBB.#.BBBB.#.BBBB.#B",
	"B#......#......#......#B",
	"B######################B",
	"BBBBBBBBBBBBBBBBBBBBBBBB",
]

# Where each character's tile sits in tiles.png (column, row).
const TILES := {
	"#": Vector2i(0, 0),
	".": Vector2i(1, 0),
	"B": Vector2i(2, 0),
}

func _ready() -> void:
	for y in LAYOUT.size():
		for x in LAYOUT[y].length():
			set_cell(Vector2i(x, y), 0, TILES[LAYOUT[y][x]])

# A random spot on the road, in world pixels (the centre of a road tile).
func random_road_position() -> Vector2:
	var roads := get_used_cells_by_id(0, TILES["#"])
	return map_to_local(roads.pick_random())
