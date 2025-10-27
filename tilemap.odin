package main

import "base:intrinsics"

// Tile_Size should just = 1 in 3d
current_tilemap: Tilemap

Tilemap :: struct {
	width:           int,
	height:          int,
	collision_tiles: [dynamic]Tile,
	entity_tiles:    [dynamic]Entity_Tag,
	exit_map:        [dynamic]bit_set[Direction],
	water_paths:     [dynamic]Water_Path,
}

init_tilemap :: proc(t: ^Tilemap, width, height: int) {
	collision_tiles := make([dynamic]Tile, width * height * TPC)
	entity_tiles := make([dynamic]Entity_Tag, width * height * TPC)
	exit_map := make([dynamic]bit_set[Direction], width * height)
	water_paths := make([dynamic]Water_Path, 0, 16)
	t.width, t.height = width, height
	t.collision_tiles = collision_tiles
	t.entity_tiles = entity_tiles
	t.exit_map = exit_map
	t.water_paths = water_paths
}

delete_tilemap :: proc(t: Tilemap) {
	delete(t.collision_tiles)
	delete(t.entity_tiles)
	delete(t.exit_map)
	delete(t.water_paths)
}

get_static_tile :: #force_inline proc(
	t: Tilemap,
	x, y: $T,
) -> Tile where intrinsics.type_is_integer(T) {
	map_width := CD * t.width
	return t.collision_tiles[int(x + (y * map_width))]
}

set_static_tile :: #force_inline proc(
	t: ^Tilemap,
	x, y: $T,
	tile: Tile,
) where intrinsics.type_is_integer(T) {
	map_width := CD * t.width
	t.collision_tiles[int(x + (y * map_width))] = tile
}

get_entity_tile :: #force_inline proc(
	t: Tilemap,
	x, y: $T,
) -> Entity_Tag where intrinsics.type_is_integer(T) {
	map_width := CD * t.width
	return t.entity_tiles_tiles[int(x + (y * map_width))]
}

set_entity_tile :: #force_inline proc(
	t: ^Tilemap,
	x, y: $T,
	entity: Entity_Tag,
) where intrinsics.type_is_integer(T) {
	map_width := CD * t.width
	t.entity_tiles[int(x + (y * map_width))] = entity
}

get_cell_exits :: #force_inline proc(
	t: Tilemap,
	cell_position: Cell_Position,
) -> bit_set[Direction] {
	return t.exit_map[int(cell_position.x) + (int(cell_position.y) * t.width)]
}

set_cell_exits :: #force_inline proc(
	t: ^Tilemap,
	cell_position: Cell_Position,
	exits: bit_set[Direction],
) {
	t.exit_map[int(cell_position.x) + (int(cell_position.y) * t.width)] = exits
}

//Returns the width and height of the given tilemap, in tiles
get_tilemap_dimensions :: proc(t: Tilemap) -> (width, height: int) {
	width, height = CD * t.width, CD * t.height
	return
}
