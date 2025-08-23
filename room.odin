package main

import intr "base:intrinsics"
import "core:slice"

CELL_WIDTH :: 16

Room :: struct {
	cells:      map[Cell_Position]Cell,
	width:      u8,
	height:     u8,
	cell_count: u8,
	position:   Cell_Position,
	rotation:   Room_Rotation,
	placed:     bool,
}

Room_Rotation :: enum u8 {
	North,
	East,
	West,
	South,
}

Map_Room :: struct {
	rotation: Room_Rotation,
	ptr:      ^Room,
}


Room_Tag :: enum {
	None,
	A,
	B,
	C,
	D,
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

// Permanent representation of a room cell
Cell :: struct {
	tiles: [256]Tile,
}

Cell_Position :: [2]i16

Tile :: enum u8 {
	Empty,
	Wall,
	OneWay,
	Door,
}

tile_index :: proc(x, y: $T) -> int where intr.type_is_integer(T) {
	return int(x + (y * CELL_WIDTH))
}

tile_global_index :: proc(x, y: $T, cell: Cell_Position) -> int where intr.type_is_integer(T) {
	return int((x + (int(cell.x) * 16)) + ((y + (int(cell.y) * 16)) * CELL_WIDTH))
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

place_room :: proc(tag: Room_Tag, position: Cell_Position, rotation: Room_Rotation) {
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
	rotation: Room_Rotation,
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

rotate_cell :: proc(in_tiles: [256]Tile, rotation: Room_Rotation) -> [256]Tile {
	if rotation == .North {
		return in_tiles
	}
	rotations: int
	#partial switch rotation {
	case .East:
		rotations = 1
	case .South:
		rotations = 2
	case .West:
		rotations = 3
	}
	tiles := in_tiles
	for rotations > 0 {
		for i in 0 ..< 16 {
			for j in i + 1 ..< 16 {
				tiles[tile_index(j, i)], tiles[tile_index(i, j)] =
					tiles[tile_index(i, j)], tiles[tile_index(j, i)]
			}
		}
		for i in 0 ..< 16 {
			start, end := 0, 15
			for start < end {
				tiles[tile_index(i, start)], tiles[tile_index(i, end)] =
					tiles[tile_index(i, end)], tiles[tile_index(i, start)]
				start += 1
				end -= 1
			}
		}
		rotations -= 1
	}
	return tiles
}

select_next_valid_tag :: proc() {
	for room, tag in rooms {
		if tag != .None && room.placed == false {
			map_screen_state.selected_room = tag
		}
	}
}
