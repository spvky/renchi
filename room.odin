package main

import intr "base:intrinsics"
import "core:fmt"
import "core:slice"

CELL_WIDTH :: 16
MAP_WIDTH :: 256

Cell_Position :: [2]i16
Tile_Position :: [2]u16

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
	tiles: [256]Tile,
	exits: bit_set[Direction],
}


Tile :: enum u8 {
	Empty,
	Wall,
	OneWay,
	Door,
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
room_pivot_from_tag :: proc(tag: Room_Tag) -> Cell_Position {
	position: Cell_Position
	#partial switch tag {
	case .A:
		position = {1, 0}
	case .D:
		position = {1, 1}
	}
	return position
}

tile_index :: proc(x, y: $T) -> int where intr.type_is_integer(T) {
	return int(x + (y * CELL_WIDTH))
}

global_index :: proc(x, y: $T) -> int where intr.type_is_integer(T) {
	return int(x + (y * MAP_WIDTH))
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
		if pos.x < 0 || pos.x > 15 || pos.y < 0 || pos.y > 15 {
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

cell_global_position :: proc(
	cell_pos, room_pos: Cell_Position,
	room_rot: Direction,
) -> Cell_Position {
	rotated_pos := cell_pos
	rotations: int
	#partial switch room_rot {
	case .East:
		rotations = 1
	case .South:
		rotations = 2
	case .West:
		rotations = 3
	}

	for _ in 0 ..< rotations {
		rotated_pos = {-rotated_pos.y, rotated_pos.x}
	}
	final_pos := rotated_pos + room_pos
	return final_pos
}

rotate_cell :: proc(
	in_tiles: [256]Tile,
	in_exits: bit_set[Direction],
	rotation: Direction,
) -> (
	out_tiles: [256]Tile,
	out_exits: bit_set[Direction],
) {
	if rotation == .North {
		return in_tiles, in_exits
	}
	for x in 0 ..< 16 {
		for y in 0 ..< 16 {
			#partial switch rotation {
			case .East:
				out_tiles[tile_index(x, y)] = in_tiles[tile_index(y, 15 - x)]
			case .South:
				out_tiles[tile_index(x, y)] = in_tiles[tile_index(15 - x, 15 - y)]
			case .West:
				out_tiles[tile_index(x, y)] = in_tiles[tile_index(15 - y, x)]
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
