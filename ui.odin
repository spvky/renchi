package main

import "core:math"
import rl "vendor:raylib"

Ui_Texture_Tag :: enum {
	Cursor,
}

load_ui_textures :: proc() -> [Ui_Texture_Tag]rl.Texture {
	return {.Cursor = rl.LoadTexture("assets/textures/map_screen_cursor.png")}
}

unload_ui_textures :: proc() {
	for texture, _ in ui_texture_atlas {
		rl.UnloadTexture(texture)
	}
}

handle_map_screen_cursor :: proc() {
	if rl.IsKeyPressed(.A) {
		map_screen_cursor.position.x = math.clamp(map_screen_cursor.position.x - 1, 0, 15)
	}
	if rl.IsKeyPressed(.D) {
		map_screen_cursor.position.x = math.clamp(map_screen_cursor.position.x + 1, 0, 15)
	}
	if rl.IsKeyPressed(.W) {
		map_screen_cursor.position.y = math.clamp(map_screen_cursor.position.y - 1, 0, 15)
	}
	if rl.IsKeyPressed(.S) {
		map_screen_cursor.position.y = math.clamp(map_screen_cursor.position.y + 1, 0, 15)
	}
}
