package main

import l "core:math/linalg"
import rl "vendor:raylib"

camera_follow :: proc() {
	player := world.player
	frametime := rl.GetFrameTime()
	if game_state == .Gameplay {
		target_pos := Vec2{player.translation.x - 200, player.translation.y - 200}
		world.camera.target = l.lerp(world.camera.target, target_pos, frametime * 20)
	}
}

move_camera :: proc() {
	player := world.player
	frametime := rl.GetFrameTime()
	world.current_cell = Cell_Position {
		i16(player.translation.x / (TILE_COUNT * TILE_SIZE)),
		i16(player.translation.y / (TILE_COUNT * TILE_SIZE)),
	}
	if game_state == .Gameplay {
		target_pos := Vec2 {
			(f32(world.current_cell.x) * (TILE_COUNT * TILE_SIZE)) - 120,
			(f32(world.current_cell.y) * (TILE_COUNT * TILE_SIZE)) - 8,
		}
		world.camera.target = l.lerp(world.camera.target, target_pos, frametime * 20)
	}
}
