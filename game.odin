/*
	Main entry point for the game
*/
package main

import "core:c"
import "core:log"
import "core:math"
import rl "vendor:raylib"

Game_State :: enum {
	Map,
	Gameplay,
}

Render_Mode :: enum {
	TwoD,
	ThreeD,
}

World :: struct {
	camera:       rl.Camera2D,
	camera3d:     rl.Camera3D,
	offset:       Vec3,
	player:       Player,
	current_cell: Cell_Position,
}

Camera_Limits :: struct {
	min: Vec2,
	max: Vec2,
}

make_world :: proc() -> World {
	player := Player {
		translation  = {128, 0},
		radius       = 8,
		acceleration = 275,
		deceleration = 0.75,
	}
	return World {
		camera = rl.Camera2D{zoom = 1},
		camera3d = rl.Camera3D{up = Vec3{0, 1, 0}, fovy = 90, projection = .PERSPECTIVE},
		offset = {145, 300, 0},
		player = player,
	}
}

CELL_COUNT :: 10
TILE_COUNT :: 25
TILE_SIZE :: 16

WINDOW_WIDTH: i32 = 1920
WINDOW_HEIGHT: i32 = 1080
SCREEN_WIDTH :: 768
SCREEN_HEIGHT :: 432
TICK_RATE :: 1.0 / 200.0

world: World
run: bool
ui_texture_atlas: [Ui_Texture_Tag]rl.Texture
rooms: [Room_Tag]Room
tilemap: [(TILE_COUNT * TILE_COUNT) * (CELL_COUNT * CELL_COUNT)]Tile
time: Time
exit_map: [CELL_COUNT * CELL_COUNT]bit_set[Direction]
game_state: Game_State
render_mode := Render_Mode.ThreeD
colliders: [dynamic]Collider
rigidbodies: [dynamic]Rigidbody
input_buffer: Input_Buffer
camera_limits: Camera_Limits
cell_exits: bit_set[Direction]


init :: proc() {
	run = true
	log.info("Rigidbodies Initialized")
	rigidbodies = make([dynamic]Rigidbody, 0, 16)
	log.info("Colliders Initialized")
	colliders = make([dynamic]Collider, 0, 64)
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Game")
	init_render_textures()
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

mapping :: proc() {
	handle_map_screen_cursor()
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
