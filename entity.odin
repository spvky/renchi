package main

import "core:log"
import rl "vendor:raylib"

entities: [dynamic]Entity

Entity_Manager :: struct {
	entities:          [dynamic]Entity,
	id_index_map:      map[Entity_Id]int,
	current_entity_id: Entity_Id,
}

make_entity_manager :: proc() -> Entity_Manager {
	entities := make([dynamic]Entity, 0, 32)
	id_index_map := make(map[Entity_Id]int, 32)
	return Entity_Manager{entities = entities, id_index_map = id_index_map}
}

get_entity :: proc(e: ^Entity_Manager, id: Entity_Id) -> ^Entity {
	index := e.id_index_map[id]
	return &e.entities[index]
}

append_entity :: proc(e: ^Entity_Manager, entity: ^Entity) {
	id := e.current_entity_id
	entity.id = id
	append(&e.entities, entity^)
	new_index := len(e.entities) - 1
	e.id_index_map[id] = new_index
	e.current_entity_id += 1
}

clear_entity_manager :: proc(e: ^Entity_Manager) {
	clear(&e.entities)
	clear(&e.id_index_map)
	e.current_entity_id = 0
}

delete_entity_manager :: proc(e: ^Entity_Manager) {
	delete(e.entities)
	delete(e.id_index_map)
}

Entity_Id :: distinct u32

Entity :: struct {
	id:              Entity_Id,
	tag:             Entity_Tag,
	state_flags:     bit_set[Entity_State_Flag;u16],
	type_flags:      bit_set[Entity_Type_Flag;u16],
	rigidbody_index: int,
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

Entity_Type_Flag :: enum u16 {
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
		Entity{tag = tag, rigidbody_index = rb_index, type_flags = {.Moveable, .Grabable}},
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
