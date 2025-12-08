package main

import "core:log"
import rl "vendor:raylib"

entities: [dynamic]Entity

Entity :: struct {
	tag:             Entity_Tag,
	fields:          Entity_Fields,
	flags:           bit_set[Entity_Flag],
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

Entity_Flag :: enum {
	Submerged,
	Electrified,
	Burning,
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
			flags = {.Standable},
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

entity_specific_physics :: proc() {
	for e in entities {
		switch e.tag {
		case .None:
		case .Box:
			rb := &rigidbodies[e.rigidbody_index]
			if .Submerged in e.flags {
				rb.velocity.y = -2
			}
		}
	}
}

entity_submersion_handling :: proc(t: Tilemap) {
	for &e in entities {
		switch e.tag {
		case .None:
		case .Box:
			rb := rigidbodies[e.rigidbody_index]
			submerged: bool
			for v in t.water_volumes {
				if water_volume_contains(v, rb.collider.translation) {
					submerged = true
				}
			}
			if submerged {
				e.flags += {.Submerged}
			} else {
				e.flags -= {.Submerged}
			}
		}
	}
}
