package main

import "core:fmt"
import "core:image/qoi"
import "core:strings"
import rl "vendor:raylib"

MAP_SIZE: Vec2 : {256, 256}
GRID_OFFSET: Vec2 = {f32(SCREEN_WIDTH) / 2, f32(SCREEN_HEIGHT) / 2} - (MAP_SIZE / 2)
MAP_CELL_SIZE :: Vec2{16, 16}

World_Map :: struct {
	rooms: [256]Room_Tag,
}

Map_Screen_State :: struct {
	cursor:        Map_Screen_Cursor,
	selected_room: Room_Tag,
	placed_rooms:  bit_set[Room_Rotation],
}

make_map_screen_state :: proc() -> Map_Screen_State {
	return Map_Screen_State{selected_room = .A}
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
	cursor_pos := vec_from_map_cell_position(cursor.position)
	// Vec2{8, 8} + Vec2{f32(cursor.position.x) * 16, f32(cursor.position.y) * 16} + GRID_OFFSET
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
		draw_room(rooms[map_screen_state.selected_room], cursor_pos, cursor.displayed_rotation)
	// can_place()
	}
}

vec_from_map_cell_position :: proc(position: Cell_Position) -> Vec2 {
	return Vec2{8, 8} + Vec2{f32(position.x) * 16, f32(position.y) * 16} + GRID_OFFSET
}

float_rotation_from_room_rotation :: proc(rotation: Room_Rotation) -> f32 {
	float_rotation: f32
	#partial switch rotation {
	case .East:
		float_rotation = 90
	case .South:
		float_rotation = 180
	case .West:
		float_rotation = 270
	}

	return float_rotation
}

draw_placed_rooms :: proc() {
	for room, _ in rooms {
		if room.placed {
			draw_room(
				room,
				vec_from_map_cell_position(room.position),
				float_rotation_from_room_rotation(room.rotation),
			)
		}
	}
}

draw_room :: proc(room: Room, position: Vec2, rotation: f32) {
	for pos, cell in room.cells {
		cell_position := Vec2{f32(pos.x * 16), f32(pos.y * 16)}
		draw_cell(cell, position, cell_position, rotation)
	}
}

draw_cell :: proc(cell: Cell, origin: Vec2, position: Vec2, rotation: f32) {
	rl.DrawRectanglePro(
		{origin.x, origin.y, MAP_CELL_SIZE.x, MAP_CELL_SIZE.y},
		-position + (MAP_CELL_SIZE / 2),
		rotation,
		rl.BLUE,
	)
	for x in 0 ..< 16 {
		for y in 0 ..< 16 {
			tile := cell.tiles[tile_index(x, y)]
			tile_color: rl.Color
			#partial switch tile {
			case .Wall:
				tile_color = {255, 255, 255, 255}
			case .OneWay:
				tile_color = {130, 130, 130, 200}
			case .Door:
				tile_color = {220, 235, 16, 255}
			}
			if tile != .Empty {
				tile_offset := Vec2{f32(x) - 7, f32(y) - 7}
				rl.DrawRectanglePro(
					{origin.x, origin.y, 1, 1},
					position + tile_offset,
					rotation + 180,
					tile_color,
				)
			}
		}
	}
}

draw_map :: proc() {
	draw_map_grid()
	draw_placed_rooms()
	draw_map_cursor()
}
