/*
	 Logic pertaining to filling the render textures and outputting them to screen
*/
package main
import rl "vendor:raylib"

GAMEPLAY_SCREEN_WIDTH :: 768
GAMEPLAY_SCREEN_HEIGHT :: 432
MAP_SCREEN_WIDTH :: 768
MAP_SCREEN_HEIGHT :: 432

gameplay_texture: rl.RenderTexture
map_texture: rl.RenderTexture

init_render_textures :: proc() {
	map_texture = rl.LoadRenderTexture(WINDOW_HEIGHT, WINDOW_HEIGHT)
	// gameplay_texture = rl.LoadRenderTexture(GAMEPLAY_SCREEN_WIDTH, GAMEPLAY_SCREEN_HEIGHT)
	gameplay_texture = rl.LoadRenderTexture(WINDOW_HEIGHT, WINDOW_HEIGHT)
}

destroy_render_textures :: proc() {
	rl.UnloadRenderTexture(map_texture)
	rl.UnloadRenderTexture(gameplay_texture)
}

write_to_map_texture :: proc() {
	rl.BeginTextureMode(map_texture)
	rl.ClearBackground(rl.PINK)
	draw_map()
	rl.EndTextureMode()
}

write_to_gameplay_texture :: proc() {
	rl.BeginTextureMode(gameplay_texture)
	rl.ClearBackground(rl.GREEN)
	rl.BeginMode3D(world.camera3d)
	draw_tilemap()
	draw_player()
	rl.EndMode3D()
	rl.EndTextureMode()
}

write_to_render_textures :: proc() {
	write_to_map_texture()
	write_to_gameplay_texture()
}

draw_map_texture :: proc(alpha: u8) {
	display_width := f32(WINDOW_WIDTH) / 2
	source := rl.Rectangle {
		x      = 0,
		// y      = f32(WINDOW_HEIGHT - MAP_SCREEN_HEIGHT),
		y      = 776,
		width  = 304,
		height = -304,
	}
	dest := rl.Rectangle {
		x      = display_width / 2,
		y      = (f32(WINDOW_HEIGHT) / 2) - display_width / 2,
		width  = display_width,
		height = display_width,
	}
	rl.DrawTexturePro(map_texture.texture, source, dest, {0, 0}, 0, {255, 255, 255, alpha})
}

draw_gameplay_texture :: proc() {
	source := rl.Rectangle {
		x      = 0,
		y      = 0,
		width  = f32(GAMEPLAY_SCREEN_WIDTH),
		height = f32(GAMEPLAY_SCREEN_HEIGHT),
	}
	dest := rl.Rectangle {
		x      = 0,
		y      = 0,
		width  = f32(WINDOW_WIDTH),
		height = f32(WINDOW_HEIGHT),
	}
	rl.DrawTexturePro(gameplay_texture.texture, source, dest, {0, 0}, 0, rl.WHITE)
}

draw_textures_to_screen :: proc() {
	map_alpha: u8
	if game_state == .Map {
		map_alpha = 255
	} else {
		map_alpha = 0
	}
	if game_state == .Gameplay {
		draw_gameplay_texture()
	}
	draw_map_texture(map_alpha)
	draw_button_container(top_row_buttons)
}

render :: proc() {
	write_to_render_textures()
	rl.BeginDrawing()
	rl.ClearBackground(rl.WHITE)
	draw_textures_to_screen()
	if ODIN_DEBUG {
		rl.DrawCircle(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 5, rl.WHITE)
		map_screen_debug()
		player_debug()
	}
	rl.EndDrawing()
}
