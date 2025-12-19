/*
	 Debug specific logic
*/
package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

map_screen_debug :: proc() {
	y_offset := 100
	i: int
	for room, tag in assets.rooms {
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
		"Player:\n\tTranslation: [%.1f,%.1f]\n\tOffset: [%.1f,%.1f]\nCurrent Cell: [%v,%v]\nDelta: %v\nFlags: \n%v\n%v",
		player.translation.x,
		player.translation.y,
		world.offset.x,
		world.offset.y,
		world.current_cell.x,
		world.current_cell.y,
		world.player.move_delta,
		world.player.state_flags,
		world.player.prev_state_flags,
	)
	rl.DrawText(strings.clone_to_cstring(debug_string), 20, 100, 16, rl.BLACK)
}
