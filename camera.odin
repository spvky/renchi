/*
	 Logic pertaining to moving and rotating the camera
*/
package main

import l "core:math/linalg"
import rl "vendor:raylib"

Camera_Limits :: struct {
	min: Vec2,
	max: Vec2,
}

camera_limits: Camera_Limits
camera_exits: bit_set[Direction]

camera_follow :: proc() {
	player := world.player
	frametime := rl.GetFrameTime()

	if ODIN_DEBUG {
		if rl.IsKeyDown(.UP) {
			world.offset.y -= 25 * frametime
		}
		if rl.IsKeyDown(.DOWN) {
			world.offset.y += 25 * frametime
		}
		if rl.IsKeyDown(.LEFT) {
			world.offset.x -= 5 * frametime
		}
		if rl.IsKeyDown(.RIGHT) {
			world.offset.x += 5 * frametime
		}
		if rl.IsKeyDown(.ONE) {
			world.camera.fovy -= 100 * frametime
		}
		if rl.IsKeyDown(.TWO) {
			world.camera.fovy += 100 * frametime
		}
	}

	world.current_cell = Cell_Position {
		i16(player.translation.x / CD),
		i16(player.translation.y / CD),
	}

	if game_state == .Gameplay {
		// set_camera_exits(world.current_cell)
		set_camera_limits_from_position(world.current_cell)

		cell_size := f32(CD)
		cell_offset := Vec3{cell_size / 2, cell_size / 2, 0}
		raw_position := l.clamp(
			player.translation - Vec2{125, 0},
			camera_limits.min,
			camera_limits.max,
		)
		target_pos := extend(raw_position, 0) + world.offset + cell_offset
		world.camera.target = l.lerp(world.camera.target, target_pos, frametime * 20)
		world.camera.position = l.lerp(
			world.camera.position,
			target_pos + Vec3{0, 0, 500},
			frametime * 20,
		)
		rl.SetShaderValue(
			assets.lighting_shader,
			assets.lighting_shader.locs[SHADER_LOC_VIEW],
			&world.camera.position,
			.VEC3,
		)
	}
}

// set_camera_exits :: proc(t: Tilemap, c: Cell_Position) {
// 	cell_exits = get_cell_exits(t, c)
// }

set_camera_limits_from_position :: proc(c: Cell_Position) {
	cell_size := f32(CD)

	current_position := Vec2 {
		f32(world.current_cell.x) * cell_size,
		f32(world.current_cell.y) * cell_size,
	}

	limit_min, limit_max := current_position, current_position

	for v in camera_exits {
		if v == .North {
			limit_min.y -= cell_size
		}
		if v == .South {
			limit_max.y += cell_size
		}
		if v == .West {
			limit_min.x -= cell_size
		}
		if v == .East {
			limit_max.x += cell_size
		}
	}
	camera_limits = Camera_Limits {
		min = limit_min,
		max = limit_max,
	}
}
