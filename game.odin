package main

import "core:c"
import "core:fmt"
import rl "vendor:raylib"

Vec2 :: [2]f32

world: World
screen_texture: rl.RenderTexture
run: bool
room: Room

WINDOW_WIDTH: i32 = 1600
WINDOW_HEIGHT: i32 = 900
SCREEN_WIDTH :: 480
SCREEN_HEIGHT :: 360


init :: proc() {
	run = true
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Game")
	screen_texture = rl.LoadRenderTexture(WINDOW_HEIGHT, WINDOW_HEIGHT)
	world = make_world()
	room = read_room(.A)
	fmt.printfln("Room: %v", room)
}

update :: proc() {
	render_scene()
	draw_to_screen()
}

shutdown :: proc() {
	rl.UnloadRenderTexture(screen_texture)
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
