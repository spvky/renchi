/*
	 Logic pertaining to filling the render textures and outputting them to screen
*/
package main
import rl "vendor:raylib"

GAMEPLAY_SCREEN_WIDTH :: 768
GAMEPLAY_SCREEN_HEIGHT :: 432
MAP_SCREEN_WIDTH :: 768
MAP_SCREEN_HEIGHT :: 432

destroy_render_textures :: proc() {
	rl.UnloadRenderTexture(assets.map_texture)
	rl.UnloadRenderTexture(assets.gameplay_texture)
}

write_to_map_texture :: proc() {
	rl.BeginTextureMode(assets.map_texture)
	rl.ClearBackground(rl.PINK)
	draw_map(world.current_tilemap)
	rl.EndTextureMode()
}

write_to_gameplay_texture :: proc() {
	rl.BeginTextureMode(assets.gameplay_texture)
	rl.ClearBackground({255, 229, 180, 255})
	rl.BeginMode3D(world.camera)
	draw_player()
	draw_entities()
	draw_tilemap(world.current_tilemap)
	rl.DrawCubeV({12, 12, 0}, V_ONE, rl.YELLOW)
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
	rl.DrawTexturePro(assets.map_texture.texture, source, dest, {0, 0}, 0, {255, 255, 255, alpha})
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
	rl.DrawTexturePro(assets.gameplay_texture.texture, source, dest, {0, 0}, 0, rl.WHITE)
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
	// draw_button_container(top_row_buttons)
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
