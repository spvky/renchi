package main

import "core:c"
import "core:fmt"
import rl "vendor:raylib"

Game_State :: enum {
	Map,
	Gameplay,
}

Vec2 :: [2]f32

WINDOW_WIDTH: i32 = 1920
WINDOW_HEIGHT: i32 = 1080
SCREEN_WIDTH :: 480
SCREEN_HEIGHT :: 270

world: World
screen_texture: rl.RenderTexture
map_screen_texture: rl.RenderTexture
run: bool
ui_texture_atlas: [Ui_Texture_Tag]rl.Texture
rooms: [Room_Tag]Room
map_screen_state: Map_Screen_State
tilemap: [65536]Tile
game_state: Game_State


init :: proc() {
	run = true
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Game")
	screen_texture = rl.LoadRenderTexture(WINDOW_HEIGHT, WINDOW_HEIGHT)
	world = make_world()
	map_screen_state = make_map_screen_state()
	fmt.printfln("WORLD SIZE: %v bytes", size_of(World))
	rooms = load_rooms()
	ui_texture_atlas = load_ui_textures()
}

update :: proc() {
	handle_map_screen_cursor()
	render_scene()
	draw_to_screen()
	free_all(context.temp_allocator)
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
