package main

import rl "vendor:raylib"

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
		shape = Rectangle{{1, 1}}
	}

	rb_index := append_elem(
		&rigidbodies,
		Rigidbody{translation = translation, snapshot = translation, shape = shape},
	)
	append(&entities, Entity{tag = tag, rigidbody_index = rb_index})
}

draw_entities :: proc() {
	for e in entities {
		switch e.tag {
			case .None:
			case .Box:
				rb := rigidbodies[e.rigidbody_index]
				pos := extend(rb.snapshot, 0)
				extents := Vec3{1,1,1}
				rl.DrawCubeV(pos, extents, rl.BLACK)
		}
	}
}
