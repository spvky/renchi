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
		min, max := limits_from_position(world.current_cell)

		camera_limits = Camera_Limits{min, max}
		cell_size := f32(TILE_COUNT * TILE_SIZE)
		cell_offset := Vec3{cell_size / 2, cell_size / 2, 0}
		raw_position := l.clamp(player.translation, min, max)
		target_pos := extend(raw_position, 0) + world.offset + cell_offset
		world.camera3d.target = l.lerp(world.camera3d.target, target_pos, frametime * 20)
		world.camera3d.position = l.lerp(
			world.camera3d.position,
			target_pos + Vec3{0, 0, 500},
			frametime * 20,
		)
	}
}

get_cell_exits :: proc(c: Cell_Position) -> bit_set[Direction] {
	exits: bit_set[Direction]
	if c.y > 0 {
		if .South in exit_map[cell_index(c.x, c.y - 1)] {
			exits = exits | {.North}
		}
	}
	if c.x > 0 {
		if .East in exit_map[cell_index(c.x - 1, c.y)] {
			exits = exits | {.West}
		}
	}
	if c.x < CELL_COUNT {
		if .West in exit_map[cell_index(c.x + 1, c.y)] {
			exits = exits | {.East}
		}
	}
	if c.y < CELL_COUNT {
		if .North in exit_map[cell_index(c.x, c.y + 1)] {
			exits = exits | {.South}
		}
	}
	return exits
}

limits_from_position :: proc(c: Cell_Position) -> (min, max: Vec2) {
	exits := get_cell_exits(c)
	cell_exits = exits
	cell_size := f32(TILE_COUNT * TILE_SIZE)

	current_position := Vec2 {
		f32(world.current_cell.x) * cell_size,
		f32(world.current_cell.y) * cell_size,
	}

	min, max = current_position, current_position

	for v in exits {
		if v == .North {
			min.y -= cell_size
		}
		if v == .South {
			max.y += cell_size
		}
		if v == .West {
			min.x -= cell_size
		}
		if v == .East {
			max.x += cell_size
		}
	}
	return min, max
}
