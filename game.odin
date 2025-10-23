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
game_state: Game_State
time: Time

Game_State :: enum {
	Map,
	Gameplay,
}

World :: struct {
	camera:     rl.Camera3D,
	offset:       Vec3,
	player:       Player,
	current_cell: Cell_Position,
}

make_world :: proc() -> World {
	player := Player {
		translation  = {128, 0},
		radius       = 8,
		acceleration = 275,
		deceleration = 0.75,
		facing = 1
	}
	return World {
		camera = rl.Camera3D{up = Vec3{0, 1, 0}, fovy = 1000, projection = .ORTHOGRAPHIC},
		offset = {145, 300, 0},
		player = player,
	}
}

Camera_Limits :: struct {
	min: Vec2,
	max: Vec2,
}

init :: proc() {
	if !ODIN_DEBUG {
		rl.SetTraceLogLevel(.ERROR)
	}
	run = true
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Game")
	init_render_textures()
	init_physics_collections()
	init_ui()
	world = make_world()
	log.infof("Rigidbodies Length: %v", len(rigidbodies))
	for rb in rigidbodies {
		log.infof("Rigidbody Translation: %v", rb.translation)
	}
	rooms = load_rooms()
	ui_texture_atlas = load_ui_textures()
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
		physics_step()
		time.simulation_time -= TICK_RATE
	}
	alpha := time.simulation_time / TICK_RATE
	world.player.snapshot = math.lerp(world.player.snapshot, world.player.translation, alpha)
}

shutdown :: proc() {
	destroy_render_textures()
	unload_ui_textures()
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
