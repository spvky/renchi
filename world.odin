/*
	Global game state
*/
package main

import "core:container/queue"
import rl "vendor:raylib"

// Struct that contains realtime global data
World :: struct {
	// Camera and player
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
	rigidbodies:     [dynamic]Rigidbody,
	lighting:        Lighting,
	event_listeners: map[Event_Type][dynamic]Event_Callback,
	event_queue:     queue.Queue(Event),
}

init_world :: proc() {
	init_physics_collections()
	init_entity_collections()
	init_events_system()
	player := Player {
		translation  = {12, 0},
		radius       = 0.5,
		acceleration = 275,
		deceleration = 0.75,
		facing       = 1,
	}
	init_tilemap(&world.current_tilemap, 5, 8)
	world.camera = rl.Camera3D {
		up         = Vec3{0, 1, 0},
		fovy       = 60,
		projection = .ORTHOGRAPHIC,
	}
	world.offset = {8, 18, 0}
	world.player = player
	world.lighting = {
		ambient = {0.1, 0.1, 0.1, 1},
	}
	register_player_event_listeners()
	// ambient_loc := rl.GetShaderLocation(assets.lighting_shader, "ambient")
	// rl.SetShaderValue(assets.lighting_shader, ambient_loc, &world.lighting.ambient, .VEC4)
	// create_point_light({12, 12, 0})
}
