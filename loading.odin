package main

import "core:encoding/csv"
import "core:fmt"
import "core:os"
import "core:strconv"

load_rooms :: proc() -> [Room_Tag]Room {
	return {
		.None = Room{},
		.A = read_room(.A),
		.B = read_room(.B),
		.C = read_room(.C),
		.D = read_room(.D),
	}
}

read_room :: proc(tag: Room_Tag) -> Room {
	filename := room_tag_as_filepath(tag, .CSV)
	r: csv.Reader
	r.trim_leading_space = true
	defer csv.reader_destroy(&r)

	cells := make(map[Cell_Position]Cell, 8)

	csv_data, ok := os.read_entire_file(filename)
	if ok {
		csv.reader_init_with_string(&r, string(csv_data))
	} else {
		fmt.printfln("Unable to open file: %v", filename)
		return Room{}
	}
	defer delete(csv_data)

	records, err := csv.read_all(&r)
	if err != nil do fmt.printfln("Failed to parse CSV file for %v\nErr: %v", filename, err)

	defer {
		for rec in records {
			delete(rec)
		}
		delete(records)
	}

	for r, i in records {
		for f, j in r {
			cx: i16 = i16(j) / 16
			cy: i16 = i16(i) / 16
			position := Cell_Position{cx, cy}
			x := i16(j) - (cx * 16)
			y := i16(i) - (cy * 16)
			if field, field_ok := strconv.parse_uint(f); field_ok {
				value := Tile(field)
				if value != .Empty {
					exists := position in cells
					if !exists {
						cells[position] = Cell{}
					}
					cell := &cells[position]
					// fmt.printfln("setting tile at %v, %v with %v", x, y, value)
					cell.tiles[tile_index(x, y)] = value
				}
			}
		}
	}
	room := Room {
		cells = cells,
	}
	parse_room_stats(&room, tag)
	return room
}

parse_room_stats :: proc(room: ^Room, tag: Room_Tag) {
	pivot := room_pivot_from_tag(tag)
	cell_count: u8
	min_x, min_y, max_x, max_y: i16
	for position, _ in room.cells {
		cell_count += 1
		if position.x < min_x {
			min_x = position.x
		}
		if position.y < min_y {
			min_y = position.y
		}
		if position.x > max_x {
			max_x = position.x
		}
		if position.y > max_y {
			max_y = position.y
		}
	}

	new_cells := make(map[Cell_Position]Cell, cell_count)

	for position, cell in room.cells {
		converted_position := position - pivot
		new_cells[converted_position] = cell
	}

	delete(room.cells)
	room.cells = new_cells
	room.width = u8(1 + (max_x - min_x))
	room.height = u8(1 + (max_y - min_y))
	room.cell_count = cell_count
}

room_tag_as_filepath :: proc(tag: Room_Tag, extension: enum {
		CSV,
		PNG,
	}) -> string {
	switch extension {
	case .CSV:
		return fmt.tprintf("assets/ldtk/renchi/simplified/%v/Main.csv", tag)
	case .PNG:
		return fmt.tprintf("assets/ldtk/renchi/simplified/%v/Main.png", tag)
	}
	return ""
}
