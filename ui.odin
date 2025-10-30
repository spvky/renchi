/*
	 Logic pertaining to the user interface
*/
package main

import rl "vendor:raylib"

ui_texture_atlas: [Ui_Texture_Tag]rl.Texture

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
