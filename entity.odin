package main

import "core:log"
import rl "vendor:raylib"

entities: [dynamic]Entity

Entity_Id :: distinct u32

Entity :: struct {
	id:                Entity_Id,
	tag:               Entity_Tag,
	state_flags:       bit_set[Entity_State_Flag;u16],
	interaction_flags: bit_set[Entity_Interaction_Flag;u16],
	rigidbody_index:   int,
}

Entity_Tag :: enum u8 {
	None,
	Box,
}

Entity_State_Flag :: enum u16 {
	Submerged,
	Electrified,
	Burning,
}

Entity_Interaction_Flag :: enum u16 {
	Moveable,
	Grabable,
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
		&world.rigidbodies,
		Rigidbody {
			snapshot = translation,
			collider = Physics_Collider{translation = translation, shape = shape},
			flags = {.Standable},
		},
	)
	rb_index := len(world.rigidbodies) - 1
	append(
		&entities,
		Entity{tag = tag, rigidbody_index = rb_index, interaction_flags = {.Moveable, .Grabable}},
	)
}

draw_entities :: proc() {
	for e in entities {
		switch e.tag {
		case .None:
		case .Box:
			rb := world.rigidbodies[e.rigidbody_index]
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
			rb := &world.rigidbodies[e.rigidbody_index]
			if .Submerged in e.state_flags {
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
			rb := world.rigidbodies[e.rigidbody_index]
			submerged: bool
			for v in t.water_volumes {
				if water_volume_contains(v, rb.collider.translation) {
					submerged = true
				}
			}
			if submerged {
				e.state_flags += {.Submerged}
			} else {
				e.state_flags -= {.Submerged}
			}
		}
	}
}
