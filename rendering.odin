package main
import rl "vendor:raylib"

render_scene :: proc() {
	rl.BeginTextureMode(screen_texture)
	rl.ClearBackground({0, 12, 240, 255})

	switch game_state {
	case .Map:
		draw_map()
	case .Gameplay:
		switch render_mode {
		case .TwoD:
			rl.BeginMode2D(world.camera)
			draw_tilemap()
			draw_player()
			rl.EndMode2D()
		case .ThreeD:
			rl.BeginMode3D(world.camera3d)
			draw_tilemap()
			draw_player()
			rl.EndMode3D()
		}
	}
	rl.EndTextureMode()
}

draw_to_screen :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	source: rl.Rectangle

	switch render_mode {
	case .TwoD:
		source = rl.Rectangle {
			x      = 0,
			y      = f32(WINDOW_HEIGHT - SCREEN_HEIGHT),
			width  = f32(SCREEN_WIDTH),
			height = -f32(SCREEN_HEIGHT),
		}
	case .ThreeD:
		if game_state == .Map {
			source = rl.Rectangle {
				x      = 0,
				y      = f32(WINDOW_HEIGHT - SCREEN_HEIGHT),
				width  = f32(SCREEN_WIDTH),
				height = -f32(SCREEN_HEIGHT),
			}
		} else {
			source = rl.Rectangle {
				x      = 0, //f32(SCREEN_WIDTH) / 2,
				y      = 0, //f32(SCREEN_HEIGHT) / 2,
				width  = f32(SCREEN_WIDTH),
				height = f32(SCREEN_HEIGHT),
			}
		}
	}
	rl.DrawTexturePro(
		screen_texture.texture,
		source,
		{0, 0, f32(WINDOW_WIDTH), f32(WINDOW_HEIGHT)},
		{0, 0},
		0,
		rl.WHITE,
	)
	rl.DrawCircle(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 5, rl.WHITE)
	if ODIN_DEBUG {
		map_screen_debug()
		player_debug()
	}
	rl.EndDrawing()
}
