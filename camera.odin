package main

import l "core:math/linalg"
import rl "vendor:raylib"

camera_follow :: proc() {
	player := world.player
	frametime := rl.GetFrameTime()
	if rl.IsKeyDown(.UP) {
		world.offset.y -= 25 * frametime
	}
	if rl.IsKeyDown(.DOWN) {
		world.offset.y += 25 * frametime
	}
	if rl.IsKeyDown(.LEFT) {
		world.offset.x -= 25 * frametime
	}
	if rl.IsKeyDown(.RIGHT) {
		world.offset.x += 25 * frametime
	}
	world.current_cell = Cell_Position {
		i16(player.translation.x / (TILE_COUNT * TILE_SIZE)),
		i16(player.translation.y / (TILE_COUNT * TILE_SIZE)),
	}

	if game_state == .Gameplay {
		// target_pos := extend(player.translation, 0) + world.offset
		cell_size := f32(TILE_COUNT * TILE_SIZE)
		cell_offset := Vec3{cell_size / 2, cell_size / 2, 0}
		target_pos :=
			Vec3{f32(world.current_cell.x) * cell_size, f32(world.current_cell.y) * cell_size, 0} +
			world.offset +
			cell_offset
		world.camera3d.target = l.lerp(world.camera3d.target, target_pos, frametime * 20)
		world.camera3d.position = l.lerp(
			world.camera3d.position,
			target_pos + Vec3{0, 0, 500},
			frametime * 20,
		)
	}
}

// move_camera :: proc() {
// 	player := world.player
// 	frametime := rl.GetFrameTime()
// 	world.current_cell = Cell_Position {
// 		i16(player.translation.x / (TILE_COUNT * TILE_SIZE)),
// 		i16(player.translation.y / (TILE_COUNT * TILE_SIZE)),
// 	}
// 	if game_state == .Gameplay {
// 		switch render_mode {
// 		case .TwoD:
// 			target_pos := Vec2 {
// 				(f32(world.current_cell.x) * (TILE_COUNT * TILE_SIZE)) - 120,
// 				(f32(world.current_cell.y) * (TILE_COUNT * TILE_SIZE)) - 8,
// 			}
// 			world.camera.target = l.lerp(world.camera.target, target_pos, frametime * 20)
// 		case .ThreeD:
// 			target_pos := Vec3 {
// 				(f32(world.current_cell.x) * (TILE_COUNT * TILE_SIZE)) - 120,
// 				(f32(world.current_cell.y) * (TILE_COUNT * TILE_SIZE)) - 8,
// 				0,
// 			}
// 		}
// 	}
// }
