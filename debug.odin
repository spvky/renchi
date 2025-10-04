package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

map_screen_debug :: proc() {
	y_offset := 100
	i: int
	for room, tag in rooms {
		if room.placed && tag != .None {
			rooms_string := fmt.tprintf(
				"Room: %v\n\tPlaced: %v\n\tPosition: %v\n\tRotation: %v",
				tag,
				room.placed,
				room.position,
				room.rotation,
			)

			rl.DrawText(
				strings.clone_to_cstring(rooms_string),
				1550,
				i32(y_offset + (i * 70)),
				16,
				rl.WHITE,
			)
			i += 1
		}
	}
}

player_debug :: proc() {
	player := world.player
	debug_string := fmt.tprintf(
		"Player:\n\tTranslation: [%.1f,%.1f]\n\tOffset: [%.1f,%.1f]\nCurrent Cell: [%v,%v]\n\tLimits:\n\t\tMin: [%v,%v]\n\t\tMax: [%v,%v]\n\tExits: %v",
		player.translation.x,
		player.translation.y,
		world.offset.x,
		world.offset.y,
		world.current_cell.x,
		world.current_cell.y,
		camera_limits.min.x,
		camera_limits.min.y,
		camera_limits.max.x,
		camera_limits.max.y,
		cell_exits,
	)
	rl.DrawText(strings.clone_to_cstring(debug_string), 20, 100, 16, rl.WHITE)
}
