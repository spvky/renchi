/*
	Global game state
*/
package main

import "core:container/queue"
import rl "vendor:raylib"

World :: struct {
	camera:          rl.Camera3D,
	offset:          Vec3,
	player_data:     Player_Data,
	player_handle:   Entity_Handle,
	current_cell:    Cell_Position,
	current_tilemap: Tilemap,
	entities:        Handle_Array(Entity, Entity_Handle),
	event_listeners: map[Event_Type][dynamic]Event_Callback,
	event_queue:     queue.Queue(Event),
}

init_world :: proc() {
	// init_physics_collections()
	// init_entity_collections()
	init_events_system()
	init_tilemap(&world.current_tilemap, 5, 8)
	world.camera = rl.Camera3D {
		up         = Vec3{0, 1, 0},
		fovy       = 60,
		projection = .ORTHOGRAPHIC,
	}
	world.offset = {8, 18, 0}
	world.player_data = Player_Data {
		acceleration = 275,
		deceleration = 0.75,
		facing       = 1,
	}
	ha_init(&world.entities, 64)
	world.player_handle = create_entity(.Player, {12, 0}, Collider_Circle{0.5})
	register_player_event_listeners()
}
