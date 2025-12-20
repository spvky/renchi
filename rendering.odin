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

render_textures_to_screen :: proc() {
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
	render_textures_to_screen()
	if ODIN_DEBUG {
		rl.DrawCircle(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 5, rl.WHITE)
		map_screen_debug()
		player_debug()
	}
	rl.EndDrawing()
}

// Specific element draw instructions
draw_tilemap :: proc(t: Tilemap) {
	draw_colliders()
	// draw_temp_colliders()
	draw_water_paths(t)
	draw_water_volumes(t)
}

draw_water_paths :: proc(t: Tilemap) {
	for p in t.water_paths {
		for s in p.segments {
			start := Vec3{f32(s.start.x), f32(s.start.y), 0}
			end: Vec3
			#partial switch s.direction {
			case .East:
				end = start + Vec3{f32(s.length), 0, 0}
			case .West:
				end = start - Vec3{f32(s.length), 0, 0}
			case .South:
				end = start + Vec3{0, f32(s.length), 0}
			}
			rl.DrawLine3D(start, end, rl.BLUE)
		}
	}
}

draw_colliders :: proc() {
	for collider in world.colliders {
		a: Vec2 = collider.min
		b: Vec2 = {collider.max.x, collider.min.y}
		c: Vec2 = collider.max
		d: Vec2 = {collider.min.x, collider.max.y}
		center := extend((a + b + c + d) / 4, 0)
		size := Vec3{collider.max.x - collider.min.x, collider.max.y - collider.min.y, 1}
		rl.DrawCubeV(center, size, rl.GRAY)
	}
}
draw_temp_colliders :: proc() {
	for collider in world.temp_colliders {
		a: Vec2 = collider.points[0]
		b: Vec2 = collider.points[1]
		c: Vec2 = collider.points[2]
		d: Vec2 = collider.points[3]
		rl.DrawLine3D(extend(a, 0.5), extend(b, 0.5), rl.RED)
		rl.DrawLine3D(extend(b, 0.5), extend(c, 0.5), rl.RED)
		rl.DrawLine3D(extend(c, 0.5), extend(d, 0.5), rl.RED)
		rl.DrawLine3D(extend(d, 0.5), extend(a, 0.5), rl.RED)
	}
}

// This feels a bit magic and wonky, but good for now
draw_water_volumes :: proc(t: Tilemap) {
	for v in t.water_volumes {
		equator := (f32(v.top) + f32(v.bottom) + 1) / 2
		meridian := (f32(v.left) + f32(v.right)) / 2
		height := f32(v.bottom) - f32(v.top)
		width := f32(v.right) - f32(v.left) + 1
		position := Vec3{meridian, equator, 0}
		extents := Vec3{width, height, 2}
		color := rl.Color{0, 0, 150, 100}
		rl.DrawCubeV(position, extents, color)
	}
}
