package main

import "core:c"
import "core:fmt"
import rl "vendor:raylib"

Vec2 :: [2]f32

world: World
screen_texture: rl.RenderTexture
map_screen_texture: rl.RenderTexture
run: bool
room: Room
ui_texture_atlas: [Ui_Texture_Tag]rl.Texture
map_screen_cursor: Map_Screen_Cursor

WINDOW_WIDTH: i32 = 1920
WINDOW_HEIGHT: i32 = 1080
SCREEN_WIDTH :: 480
SCREEN_HEIGHT :: 270

init :: proc() {
	run = true
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Game")
	screen_texture = rl.LoadRenderTexture(WINDOW_HEIGHT, WINDOW_HEIGHT)
	world = make_world()
	room = read_room(.A)
	ui_texture_atlas = load_ui_textures()


}

update :: proc() {
	handle_map_screen_cursor()
	render_scene()
	draw_to_screen()
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
