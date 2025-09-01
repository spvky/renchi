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
				150,
				i32(y_offset + (i * 70)),
				16,
				rl.WHITE,
			)
			i += 1
		}
	}
}
