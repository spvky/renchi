/*
	 Logic pertaining to actually placing tiles on the map and viewing the map screen
*/
package main

import "core:math"
import "core:slice"
import rl "vendor:raylib"

MAP_SIZE: Vec2 : {250, 250}
// GRID_OFFSET: Vec2 = {f32(SCREEN_WIDTH) / 2, f32(SCREEN_HEIGHT) / 2} - (MAP_SIZE / 2)
GRID_OFFSET: Vec2 = {27, 27}
MAP_CELL_SIZE :: Vec2{25, 25}
CELL_WIDTH :: 25
TILE_COUNT :: 25
MAP_WIDTH :: 250
CELL_COUNT :: 10
TILE_SIZE :: 16

rooms: [Room_Tag]Room
tilemap: [(TILE_COUNT * TILE_COUNT) * (CELL_COUNT * CELL_COUNT)]Tile
cell_exits: bit_set[Direction]
exit_map: [CELL_COUNT * CELL_COUNT]bit_set[Direction]
map_screen_state := Map_Screen_State {
	selected_room = .A,
}

Room :: struct {
	cells:      map[Cell_Position]Cell,
	width:      u8,
	height:     u8,
	cell_count: u8,
	position:   Cell_Position,
	rotation:   Direction,
	placed:     bool,
}

Cell :: struct {
	tiles: [TILE_COUNT * TILE_COUNT]Tile,
	exits: bit_set[Direction],
}

Tile :: enum u8 {
	Empty,
	Wall,
	OneWay,
	Door,
	Water,
}

Direction :: enum u8 {
	North,
	East,
	West,
	South,
}

Room_Tag :: enum {
	None,
	A,
	B,
	C,
	D,
}

Map_Screen_State :: struct {
	cursor:        Map_Screen_Cursor,
	selected_room: Room_Tag,
}

Map_Screen_Cursor :: struct {
	position:           Cell_Position,
	rotation:           Direction,
	target_rotation:    f32,
	displayed_rotation: f32,
	mode:               Map_Screen_Cursor_Mode,
}

Map_Screen_Cursor_Mode :: enum {
	Place,
	Select,
}

rotate_direction :: proc(dir: Direction, rotation: Direction) -> Direction {
	new_dir := dir
	#partial switch rotation {
	case .East:
		switch dir {
		case .North:
			new_dir = .East
		case .East:
			new_dir = .South
		case .South:
			new_dir = .West
		case .West:
			new_dir = .North
		}
	case .South:
		switch dir {
		case .North:
			new_dir = .South
		case .East:
			new_dir = .West
		case .South:
			new_dir = .North
		case .West:
			new_dir = .East
		}
	case .West:
		switch dir {
		case .North:
			new_dir = .West
		case .East:
			new_dir = .North
		case .South:
			new_dir = .East
		case .West:
			new_dir = .South
		}
	}
	return new_dir
}

can_place :: proc(positions: []Cell_Position) -> bool {
	can_place := true
	placed_positions := make([dynamic]Cell_Position, 0, 64, allocator = context.temp_allocator)
	for room, tag in rooms {
		if room.placed {
			append_elems(
				&placed_positions,
				..positions_from_rotation(tag, room.position, room.rotation)[:],
			)
		}
	}
	for pos in positions {
		if slice.contains(placed_positions[:], pos) {
			can_place = false
		}
		if pos.x < 0 || pos.x >= CELL_COUNT || pos.y < 0 || pos.y >= CELL_COUNT {
			can_place = false
		}
	}
	return can_place
}

place_room :: proc(tag: Room_Tag, position: Cell_Position, rotation: Direction) {
	room := &rooms[tag]
	room.placed = true
	room.position = position
	room.rotation = rotation
	select_next_valid_tag()
	map_screen_state.cursor.rotation = .North
	map_screen_state.cursor.target_rotation = 0
	map_screen_state.cursor.displayed_rotation = 0
}

positions_from_rotation :: proc(
	tag: Room_Tag,
	origin: Cell_Position,
	rotation: Direction,
) -> [dynamic]Cell_Position {
	room := rooms[tag]
	positions_to_place := make([dynamic]Cell_Position, 0, 4, allocator = context.temp_allocator)

	rotations: int

	#partial switch rotation {
	case .East:
		rotations = 1
	case .South:
		rotations = 2
	case .West:
		rotations = 3
	}
	for position, _ in room.cells {
		rotated_position := position

		for _ in 0 ..< rotations {
			rotated_position = {-rotated_position.y, rotated_position.x}
		}
		rotated_position += origin
		append(&positions_to_place, rotated_position)
	}
	return positions_to_place
}

rotate_cell :: proc(
	in_tiles: [TILE_COUNT * TILE_COUNT]Tile,
	in_exits: bit_set[Direction],
	rotation: Direction,
) -> (
	out_tiles: [TILE_COUNT * TILE_COUNT]Tile,
	out_exits: bit_set[Direction],
) {
	if rotation == .North {
		return in_tiles, in_exits
	}
	for x in 0 ..< TILE_COUNT {
		for y in 0 ..< TILE_COUNT {
			#partial switch rotation {
			case .East:
				out_tiles[tile_index(x, y)] = in_tiles[tile_index(y, (TILE_COUNT - 1) - x)]
			case .South:
				out_tiles[tile_index(x, y)] =
					in_tiles[tile_index((TILE_COUNT - 1) - x, (TILE_COUNT - 1) - y)]
			case .West:
				out_tiles[tile_index(x, y)] = in_tiles[tile_index((TILE_COUNT - 1) - y, x)]
			}
		}
	}
	for e in in_exits {
		out_exits += {rotate_direction(e, rotation)}
	}
	return
}

select_next_valid_tag :: proc() {
	for room, tag in rooms {
		if tag != .None && room.placed == false {
			map_screen_state.selected_room = tag
		}
	}
}

draw_map_grid :: proc() {
	grid_color := rl.Color{255, 255, 255, 125}
	line_color := rl.Color{0, 0, 0, 25}
	rl.DrawRectangleV(GRID_OFFSET, MAP_SIZE, grid_color)
	for i in 1 ..< CELL_COUNT {
		i_f32 := f32(i) * TILE_COUNT
		rl.DrawRectangleV(GRID_OFFSET - Vec2{0, 1} + Vec2{0, i_f32}, {MAP_SIZE.x, 2}, line_color)
		rl.DrawRectangleV(GRID_OFFSET - Vec2{1, 0} + Vec2{i_f32, 0}, {2, MAP_SIZE.y}, line_color)
	}
}

draw_map_cursor :: proc() {
	cursor := &map_screen_state.cursor
	cursor_pos := vec_from_map_cell_position(cursor.position)
	if cursor.mode == .Place && game_state == .Map {
		draw_room(rooms[map_screen_state.selected_room], cursor_pos, cursor.displayed_rotation)
	} else {
		rl.DrawTexturePro(
			ui_texture_atlas[.Cursor],
			{0, 0, 16, 16},
			{cursor_pos.x, cursor_pos.y, 25, 25},
			{8, 8},
			0,
			rl.WHITE,
		)
	}
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
		cell_position := Vec2{f32(pos.x * TILE_COUNT), f32(pos.y * TILE_COUNT)}
		draw_cell(cell, position, cell_position, rotation)
	}
}

draw_cell :: proc(cell: Cell, origin: Vec2, position: Vec2, rotation: f32) {
	rl.DrawRectanglePro(
		{origin.x, origin.y, TILE_COUNT, TILE_COUNT},
		-position + (f32(TILE_COUNT) / 2),
		rotation,
		rl.BLUE,
	)
	for x in 0 ..< TILE_COUNT {
		for y in 0 ..< TILE_COUNT {
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
				tile_offset := Vec2{f32(x) - 11.5, f32(y) - 11.5}
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

handle_map_screen_cursor :: proc() {
	cursor := &map_screen_state.cursor
	// Cursor Position
	if rl.IsKeyPressed(.A) {
		cursor.position.x = math.clamp(cursor.position.x - 1, 0, 9)
	}
	if rl.IsKeyPressed(.D) {
		cursor.position.x = math.clamp(cursor.position.x + 1, 0, 9)
	}
	if rl.IsKeyPressed(.W) {
		cursor.position.y = math.clamp(cursor.position.y - 1, 0, 9)
	}
	if rl.IsKeyPressed(.S) {
		cursor.position.y = math.clamp(cursor.position.y + 1, 0, 9)
	}
	// Cursor Rotation
	if rl.IsKeyPressed(.R) {
		cursor.target_rotation += 90
		switch cursor.rotation {
		case .North:
			cursor.rotation = .East
		case .East:
			cursor.rotation = .South
		case .South:
			cursor.rotation = .West
		case .West:
			cursor.rotation = .North
		}
	}

	cursor.displayed_rotation = math.lerp(
		cursor.displayed_rotation,
		cursor.target_rotation,
		rl.GetFrameTime() * 10,
	)

	// Room Placement
	if rl.IsKeyPressed(.SPACE) {
		tag := map_screen_state.selected_room
		position := cursor.position
		rotation := cursor.rotation
		placement_positions := positions_from_rotation(tag, position, rotation)
		if can_place(placement_positions[:]) {
			place_room(tag, position, rotation)
		}
	}

	if rl.IsKeyPressed(.ENTER) {
		bake_map()
		game_state = .Gameplay
	}

	if rl.IsKeyPressed(.BACKSPACE) {
		reset_map()
		game_state = .Map
	}
}

mapping :: proc() {
	handle_map_screen_cursor()
}
