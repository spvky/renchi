package main
import rl "vendor:raylib"

render_scene :: proc() {
	rl.BeginTextureMode(screen_texture)
	rl.ClearBackground({0, 12, 240, 255})
	rl.BeginMode2D(world.camera)
	switch game_state {
	case .Map:
		draw_map()
	case .Gameplay:
		draw_tilemap()
	}
	rl.EndMode2D()
	rl.EndTextureMode()
}

draw_to_screen :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	rl.DrawTexturePro(
		screen_texture.texture,
		{0, f32(WINDOW_HEIGHT - SCREEN_HEIGHT), f32(SCREEN_WIDTH), -f32(SCREEN_HEIGHT)},
		{0, 0, f32(WINDOW_WIDTH), f32(WINDOW_HEIGHT)},
		{0, 0},
		0,
		rl.WHITE,
	)
	map_screen_debug()
	rl.EndDrawing()
}
