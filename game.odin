package main

import "core:c"
import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Game_State :: enum {
	Map,
	Gameplay,
}

World :: struct {
	camera: rl.Camera2D,
	player: Player,
}

make_world :: proc() -> World {
	player_rigidbody := Rigidbody {
		shape = Circle{radius = 8},
	}
	player := Player {
		rigidbody = &player_rigidbody,
	}
	append(&rigidbodies, player_rigidbody)
	return World{camera = rl.Camera2D{zoom = 1}, player = player}
}

WINDOW_WIDTH: i32 = 1920
WINDOW_HEIGHT: i32 = 1080
SCREEN_WIDTH :: 480
SCREEN_HEIGHT :: 270
TILE_SIZE :: 16
TICK_RATE :: 1.0 / 200.0

world: World
screen_texture: rl.RenderTexture
map_screen_texture: rl.RenderTexture
run: bool
ui_texture_atlas: [Ui_Texture_Tag]rl.Texture
rooms: [Room_Tag]Room
map_screen_state: Map_Screen_State
tilemap: [65536]Tile
time: Time
exit_map: [256]bit_set[Direction]
game_state: Game_State
colliders: [dynamic]Collider
rigidbodies: [dynamic]Rigidbody


init :: proc() {
	run = true
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Game")
	screen_texture = rl.LoadRenderTexture(WINDOW_HEIGHT, WINDOW_HEIGHT)
	world = make_world()
	map_screen_state = make_map_screen_state()
	rooms = load_rooms()
	ui_texture_atlas = load_ui_textures()
	colliders := make([dynamic]Collider, 0, 64)
	rigidbodies := make([dynamic]Rigidbody, 0, 16)
}

update :: proc() {
	switch game_state {
	case .Map:
		mapping()
	case .Gameplay:
		playing()
	}
	render_scene()
	draw_to_screen()
	free_all(context.temp_allocator)
}

mapping :: proc() {
	handle_map_screen_cursor()
}

playing :: proc() {
	move_camera()
	frametime := rl.GetFrameTime()

	if !time.started {
		time.t = f32(rl.GetTime())
		time.started = true
	}
	// get playing input
	t1 := f32(rl.GetTime())
	elapsed := math.min(t1 - time.t, 0.25)
	time.t = t1
	time.simulation_time += elapsed
	for time.simulation_time >= TICK_RATE {
		//Physics step
		time.simulation_time -= TICK_RATE
	}
}

shutdown :: proc() {
	rl.UnloadRenderTexture(screen_texture)
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
