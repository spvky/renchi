package main

import l "core:math/linalg"
import rl "vendor:raylib"

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
			world.offset.x -= 25 * frametime
		}
		if rl.IsKeyDown(.RIGHT) {
			world.offset.x += 25 * frametime
		}
	}

	world.current_cell = Cell_Position {
		i16(player.translation.x / (TILE_COUNT * TILE_SIZE)),
		i16(player.translation.y / (TILE_COUNT * TILE_SIZE)),
	}

	if game_state == .Gameplay {
		set_cell_exits(world.current_cell)
		set_camera_limits_from_position(world.current_cell)

		cell_size := f32(TILE_COUNT * TILE_SIZE)
		cell_offset := Vec3{cell_size / 2, cell_size / 2, 0}
		raw_position := l.clamp(player.translation, camera_limits.min, camera_limits.max)
		target_pos := extend(raw_position, 0) + world.offset + cell_offset
		world.camera3d.target = l.lerp(world.camera3d.target, target_pos, frametime * 20)
		world.camera3d.position = l.lerp(
			world.camera3d.position,
			target_pos + Vec3{0, 0, 500},
			frametime * 20,
		)
	}
}

set_cell_exits :: proc(c: Cell_Position) {
	cell_exits = exit_map[cell_index(c.x, c.y)]
}

set_camera_limits_from_position :: proc(c: Cell_Position) {
	cell_size := f32(TILE_COUNT * TILE_SIZE)

	current_position := Vec2 {
		f32(world.current_cell.x) * cell_size,
		f32(world.current_cell.y) * cell_size,
	}

	limit_min, limit_max := current_position, current_position

	for v in cell_exits {
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
