package main

import "core:container/queue"
import rl "vendor:raylib"

New_World :: struct {
	camera:          rl.Camera3D,
	offset:          Vec3,
	player:          Player,
	// Tilemap
	current_cell:    Cell_Position,
	current_tilemap: Tilemap,
	// Physics collections
	colliders:       [dynamic]Static_Collider,
	entities:        Handle_Array(New_Entity, Entity_Handle),
	temp_colliders:  [dynamic]Temp_Collider,
	event_listeners: map[Event_Type][dynamic]Event_Callback,
	event_queue:     queue.Queue(Event),
}


New_Entity :: struct {
	handle:            Entity_Handle,
	tag:               Entity_Tag,
	state_flags:       bit_set[Entity_State_Flag;u8],
	interaction_flags: bit_set[Entity_Interaction_Flag;u8],
	rigidbody:         New_Rigidbody,
	data:              rawptr,
}

New_Rigidbody :: struct {
	translation: Vec2,
	snapshot:    Vec2,
	rotation:    f32,
	shape:       Collider_Shape,
	rb_flags:    bit_set[Rigidbody_Flags;u8],
}


Rigidbody_Flags :: enum u8 {
	Sensor,
	Rot_Lock,
	X_Trans_Lock,
	Y_Trans_Lock,
	Static,
}

Entity_Handle :: distinct Handle

some_proc :: proc() {
	rb := world.entities.items.rigidbody
}
