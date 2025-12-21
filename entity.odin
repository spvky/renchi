package main

import "core:log"
import rl "vendor:raylib"

Entity :: struct {
	handle:            Entity_Handle,
	tag:               Entity_Tag,
	interaction_flags: bit_set[Entity_Interaction_Flag;u8],
	state_flags:       bit_set[Entity_State_Flag;u8],
	using rigidbody:   Rigidbody,
}

Entity_Handle :: distinct Handle

Entity_Tag :: enum u8 {
	None,
	Player,
	Box,
	Level_Collision,
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

// Creates an entity and adds it to the entity collection
create_entity :: proc(
	tag: Entity_Tag,
	translation: Vec2,
	shape: Collider_Shape,
	interaction_flags: bit_set[Entity_Interaction_Flag] = {},
	state_flags: bit_set[Entity_State_Flag] = {},
	rigidbody_flags: bit_set[Rigidbody_Flags] = {},
	collision_flags: bit_set[Collision_Flag] = {},
	data: rawptr = nil,
) -> Entity_Handle {
	e: Entity
	e.tag = tag
	e.translation = translation
	e.snapshot = translation
	e.shape = shape
	switch tag {
	case .Player:
	case .Box:
	case .Level_Collision:
		e.shape = shape

		if card(rigidbody_flags) == 0 {
			e.rb_flags = {.Static}
		} else {
			e.rb_flags = rigidbody_flags
		}

		if card(collision_flags) == 0 {
			e.collision_flags = {.Clingable, .Standable}
		} else {
			e.collision_flags = collision_flags
		}
	}

	return ha_add(&world.entities, e)
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
