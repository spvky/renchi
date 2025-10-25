package main

initial_entity_map: [(TILE_COUNT * TILE_COUNT) * (CELL_COUNT * CELL_COUNT)]Entity_Tag
entities: [dynamic]Entity

Entity_Tag :: enum u8 {
	None,
	Box,
}

Entity :: struct {
	tag:             Entity_Tag,
	rigidbody_index: int,
}

init_entity_collections :: proc() {
	entities = make([dynamic]Entity, 0, 32)
}

clear_entity_collections :: proc() {
	clear(&entities)
}

delete_entity_collections :: proc() {
	delete(entities)
}

make_entity :: proc(translation: Vec2, tag: Entity_Tag) {
	shape: Collision_Shape

	switch tag {
	case .None:
		return
	case .Box:
		shape = Rectangle{{16, 16}}
	}

	rb_index := append_elem(
		&rigidbodies,
		Rigidbody{translation = translation, snapshot = translation, shape = shape},
	)
	append(&entities, Entity{tag = tag, rigidbody_index = rb_index})
}
