package main

import rl "vendor:raylib"

draw_room :: proc(room: Map_Room) {
	cursor_pos := rl.GetMousePosition()
	for position, cell in room.ptr.cells {
		cell_position := cursor_pos + Vec2{f32(position.x * 16), f32(position.y * 16)}
		draw_cell(cell, cell_position)
	}
}

draw_cell :: proc(cell: Cell, origin: Vec2) {
	rl.DrawRectangleV(origin, {16, 16}, rl.WHITE)
}

// Concept of rooms might not matter as much when in the world map, everything will just become cells at that point
World_Map :: struct {
	cells: map[Cell_Position]Cell,
	rooms: map[Cell_Position]Room_Tag,
}
