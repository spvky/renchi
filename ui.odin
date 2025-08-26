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
	cursor := &map_screen_state.cursor
	// Cursor Position
	if rl.IsKeyPressed(.A) {
		cursor.position.x = math.clamp(cursor.position.x - 1, 0, 15)
	}
	if rl.IsKeyPressed(.D) {
		cursor.position.x = math.clamp(cursor.position.x + 1, 0, 15)
	}
	if rl.IsKeyPressed(.W) {
		cursor.position.y = math.clamp(cursor.position.y - 1, 0, 15)
	}
	if rl.IsKeyPressed(.S) {
		cursor.position.y = math.clamp(cursor.position.y + 1, 0, 15)
	}
	// Cursor Rotation
	if rl.IsKeyPressed(.R) {
		cursor.target_rotation += 90
		switch cursor.rotation {
		case .North:
			cursor.rotation = .East
		case .East:
			cursor.rotation = .South
		case .South:
			cursor.rotation = .West
		case .West:
			cursor.rotation = .North
		}
	}

	cursor.displayed_rotation = math.lerp(
		cursor.displayed_rotation,
		cursor.target_rotation,
		rl.GetFrameTime() * 10,
	)

	// Room Placement
	if rl.IsKeyPressed(.SPACE) {
		tag := map_screen_state.selected_room
		position := cursor.position
		rotation := cursor.rotation
		placement_positions := positions_from_rotation(tag, position, rotation)
		if can_place(placement_positions[:]) {
			place_room(tag, position, rotation)
		}
	}

	if rl.IsKeyPressed(.ENTER) {
		bake_map()
		game_state = .Gameplay
	}

	if rl.IsKeyPressed(.BACKSPACE) {
		reset_map()
		game_state = .Map
	}
}
