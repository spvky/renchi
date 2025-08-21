package main

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

MAP_SIZE: Vec2 : {256, 256}
GRID_OFFSET: Vec2 = {f32(SCREEN_WIDTH) / 2, f32(SCREEN_HEIGHT) / 2} - (MAP_SIZE / 2)
MAP_CELL_SIZE :: Vec2{16, 16}

World_Map :: struct {
	cells:      [256]Cell,
	rooms:      [256]Room_Tag,
	occupation: [256]bool,
}

Map_Screen_State :: struct {
	cursor:        Map_Screen_Cursor,
	selected_room: Room_Tag,
	placed_rooms:  bit_set[Room_Rotation],
}

Map_Screen_Cursor :: struct {
	position:           Cell_Position,
	rotation:           Room_Rotation,
	target_rotation:    f32,
	displayed_rotation: f32,
	mode:               Map_Screen_Cursor_Mode,
}

Map_Screen_Cursor_Mode :: enum {
	Place,
	Select,
}

map_screen_debug :: proc() {
	cursor_string := fmt.tprintf(
		"Map Screen\nCursor: %v\nSelected Room: %v\nRotation: %v",
		map_screen_state.cursor,
		map_screen_state.selected_room,
		map_screen_state.cursor.rotation,
	)

	rl.DrawText(strings.clone_to_cstring(cursor_string), 1200, 100, 16, rl.WHITE)

	positions_to_place := make([dynamic]Cell_Position, 0, 4, allocator = context.temp_allocator)

	rotations: int

	#partial switch map_screen_state.cursor.rotation {
	case .East:
		rotations = 1
	case .South:
		rotations = 2
	case .West:
		rotations = 3
	}
	for position, cell in selected_room().cells {
		rotated_position := position

		for _ in 0 ..< rotations {
			rotated_position = {-rotated_position.y, rotated_position.x}
		}
		append(&positions_to_place, rotated_position)
	}

	positions_string := fmt.tprintf(
		"Rotations: %v\nPositions to place\n%v",
		rotations,
		positions_to_place,
	)

	rl.DrawText(strings.clone_to_cstring(positions_string), 200, 100, 16, rl.WHITE)
}

draw_map_grid :: proc() {
	grid_color := rl.Color{255, 255, 255, 125}
	line_color := rl.Color{0, 0, 0, 25}
	rl.DrawRectangleV(GRID_OFFSET, MAP_SIZE, grid_color)
	for i in 1 ..< 16 {
		i_f32 := f32(i) * 16
		// Horizontal Line
		rl.DrawRectangleV(GRID_OFFSET - Vec2{0, 1} + Vec2{0, i_f32}, {MAP_SIZE.x, 2}, line_color)
		// Vertical lines
		rl.DrawRectangleV(GRID_OFFSET - Vec2{1, 0} + Vec2{i_f32, 0}, {2, MAP_SIZE.y}, line_color)
	}
}

draw_map_cursor :: proc() {
	cursor := &map_screen_state.cursor
	cursor_pos :=
		Vec2{8, 8} + Vec2{f32(cursor.position.x) * 16, f32(cursor.position.y) * 16} + GRID_OFFSET
	switch cursor.mode {
	case .Select:
		rl.DrawTexturePro(
			ui_texture_atlas[.Cursor],
			{0, 0, 16, 16},
			{cursor_pos.x, cursor_pos.y, 16, 16},
			{8, 8},
			0,
			rl.WHITE,
		)
	case .Place:
		draw_room(selected_room(), cursor_pos, cursor.displayed_rotation)
	}
}

draw_room :: proc(room: Room, position: Vec2, rotation: f32) {
	room_cell_count := len(room.cells)

	// fmt.printfln("Cells in room: %v", room_cell_count)
	for pos, cell in room.cells {
		cell_position := Vec2{f32(pos.x * 16), f32(pos.y * 16)}
		draw_cell(cell, position, cell_position, rotation)
	}
}

draw_cell :: proc(cell: Cell, origin: Vec2, position: Vec2, rotation: f32) {
	// rl.DrawRectangleV(position, MAP_CELL_SIZE, rl.WHITE)
	true_position := origin + position
	rl.DrawRectanglePro(
		{origin.x, origin.y, MAP_CELL_SIZE.x, MAP_CELL_SIZE.y},
		-position + (MAP_CELL_SIZE / 2),
		rotation,
		rl.WHITE,
	)
}
