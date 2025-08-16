package main

import rl "vendor:raylib"

render_scene :: proc() {
	rl.BeginTextureMode(screen_texture)
	rl.ClearBackground({0,12,240,255})
	// Draw the scene here
	rl.EndTextureMode()
}

draw_to_screen :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	rl.DrawTexturePro(
		screen_texture.texture,
		{0, 0, 800, -450},
		{0, 0, 1600, 900},
		{0, 0},
		0,
		rl.WHITE,
	)
	rl.EndDrawing()
}
