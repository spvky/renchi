package main

import "core:fmt"
import rl "vendor:raylib"

MAP_SIZE: Vec2 : {256, 256}
GRID_OFFSET: Vec2 = {f32(SCREEN_WIDTH) / 2, f32(SCREEN_HEIGHT) / 2} - (MAP_SIZE / 2)

Map_Screen_Cursor :: struct {
	position: Cell_Position,
	rotation: Room_Rotation,
	mode:     Map_Screen_Cursor_Mode,
}

Map_Screen_Cursor_Mode :: enum {
	Select,
	Place,
}

draw_map_grid :: proc() {
	grid_color := rl.Color{255, 255, 255, 125}
	line_color := rl.Color{0, 0, 0, 25}
	rl.DrawRectangleV(GRID_OFFSET, MAP_SIZE, grid_color)
	for i in 1 ..< 16 {
		i_f32 := f32(i) * 16
		// Horizontal Line
		rl.DrawRectangleV(GRID_OFFSET + Vec2{0, i_f32}, {MAP_SIZE.x, 2}, line_color)
		// Vertical lines
		rl.DrawRectangleV(GRID_OFFSET + Vec2{i_f32, 0}, {2, MAP_SIZE.y}, line_color)
	}
}

draw_map_cursor :: proc() {
	#partial switch map_screen_cursor.mode {
	case .Select:
		cursor_pos :=
			Vec2{f32(map_screen_cursor.position.x) * 16, f32(map_screen_cursor.position.y) * 16} +
			GRID_OFFSET
		rl.DrawTextureV(ui_texture_atlas[.Cursor], cursor_pos, rl.WHITE)
	}
}

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
