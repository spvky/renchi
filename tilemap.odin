package main


Tilemap :: struct {
	width:           int,
	height:          int,
	collision_tiles: [dynamic]Tile,
	entity_tiles:    [dynamic]Entity,
}

init_tilemap :: proc(t: ^Tilemap, width, height: int) {
	collision_tiles := make([dynamic]Tile, width * height * TILES_PER_CELL)
	entity_tiles := make([dynamic]Entity, width * height * TILES_PER_CELL)
	t.width, t.height = width, height
	t.entity_tiles, t.collision_tiles = entity_tiles, collision_tiles
}

delete_tilemap :: proc(t: Tilemap) {
	delete(t.collision_tiles)
	delete(t.entity_tiles)
}
