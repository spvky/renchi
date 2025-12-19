/*
	Main entry point for the game
*/
package main

import "core:c"
import "core:log"
import "core:math"
import rl "vendor:raylib"


WINDOW_WIDTH: i32 = 1920
WINDOW_HEIGHT: i32 = 1080
SCREEN_WIDTH :: 768
SCREEN_HEIGHT :: 432
TICK_RATE :: 1.0 / 200.0

run: bool
world: World
assets: Assets
game_state: Game_State
time: Time

Game_State :: enum {
	Map,
	Gameplay,
}

init :: proc() {
	if !ODIN_DEBUG {
		rl.SetTraceLogLevel(.ERROR)
	}
	run = true
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Game")
	load_assets()
	init_world()
}

update :: proc() {
	switch game_state {
	case .Map:
		mapping()
	case .Gameplay:
		playing()
	}
	render()
	free_all(context.temp_allocator)
}

playing :: proc() {
	camera_follow()

	// light_pos := Vec3 {
	// 	math.floor(world.player.snapshot.x * 100 + 0.05) / 100,
	// 	math.floor(world.player.snapshot.y * 100 + 0.05) / 100,
	// 	0,
	// }
	// log.debugf("Setting light position to %v", light_pos)
	// set_light_position(&world.lighting.lights[0], light_pos)

	if !time.started {
		time.t = f32(rl.GetTime())
		time.started = true
	}
	poll_input()
	t1 := f32(rl.GetTime())
	elapsed := math.min(t1 - time.t, 0.25)
	time.t = t1
	time.simulation_time += elapsed
	for time.simulation_time >= TICK_RATE {
		process_events()
		physics_step()
		time.simulation_time -= TICK_RATE
	}
	alpha := time.simulation_time / TICK_RATE
	world.player.snapshot = math.lerp(world.player.snapshot, world.player.translation, alpha)
	for &rb in world.rigidbodies {
		rb.snapshot = math.lerp(rb.snapshot, rb.collider.translation, alpha)
	}
}

shutdown :: proc() {
	destroy_render_textures()
	unload_ui_textures()
	delete_entity_collections()
	delete_physics_collections()
	delete_tilemap(world.current_tilemap)
	rl.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		run = !rl.WindowShouldClose()
	}
	return run
}

parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(c.int(WINDOW_WIDTH), c.int(WINDOW_WIDTH))
}
