package main

import "core:log"
import rl "vendor:raylib"

entities: [dynamic]Entity

Entity :: struct {
	tag:             Entity_Tag,
	fields:          Entity_Fields,
	rigidbody_index: int,
}

Entity_Tag :: enum u8 {
	None,
	Box,
}

Entity_Fields :: union {
	Entity_Box,
}

Entity_Box :: struct {
	state: Box_State,
}

Box_State :: enum {
	Grounded,
	Falling,
	Water,
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
	shape: Collider_Shape

	switch tag {
	case .None:
		return
	case .Box:
		shape = Collision_Rect{{1, 1}}
	}

	append(
		&rigidbodies,
		Rigidbody {
			snapshot = translation,
			collider = Physics_Collider{translation = translation, shape = shape},
		},
	)
	rb_index := len(rigidbodies) - 1
	append(&entities, Entity{tag = tag, rigidbody_index = rb_index})
}

draw_entities :: proc() {
	for e in entities {
		switch e.tag {
		case .None:
		case .Box:
			rb := rigidbodies[e.rigidbody_index]
			pos := extend(rb.snapshot, 0)
			extents := Vec3{1, 1, 1}
			rl.DrawCubeV(pos, extents, rl.BLACK)
		}
	}
}
