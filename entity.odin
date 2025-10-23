package main

initial_entity_map: [(TILE_COUNT * TILE_COUNT) * (CELL_COUNT * CELL_COUNT)]Entity_Tag

Entity_Tag :: enum u8 {
	None,
	Box,
}

Entity :: struct {
	tag: Entity_Tag,
	position: Vec2,
	velocity: Vec2,
	collision_shape: Collision_Shape,
}
