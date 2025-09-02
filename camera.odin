package main

import l "core:math/linalg"
import rl "vendor:raylib"

move_camera :: proc() {
	player := world.player
	frametime := rl.GetFrameTime()
	world.current_cell = Cell_Position {
		i16(player.translation.x / 256),
		i16(player.translation.y / 256),
	}
	if game_state == .Gameplay {
		target_pos := Vec2 {
			(f32(world.current_cell.x) * 256) - 120,
			(f32(world.current_cell.y) * 256) - 8,
		}
		world.camera.target = l.lerp(world.camera.target, target_pos, frametime * 20)
	}
}
