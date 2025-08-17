package main

import "core:encoding/csv"
import "core:fmt"
import "core:os"

read_room :: proc(tag: Room_Tag) -> Room {
	filename := room_tag_as_filepath(tag, .CSV)
	r: csv.Reader
	r.trim_leading_space = true
	defer csv.reader_destroy(&r)

	raw_cells := make(map[Cell_Position]Cell, 8, allocator = context.temp_allocator)
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
	width := len(records[0]) / 16
	height := len(records) / 16


	rooms: [10][10]Cell

	for r, i in records {
		for f, j in r {
			x: i16 = i16(j) / 12 //X and Y inform which room cell we are populating
			y: i16 = i16(i) / 12 //X and Y inform which room cell we are populating
			ix := i16(j) - (x * 12)
			iy := i16(i) - (y * 12)
			current_cell := &rooms[x][y]
			current_cell.location = Tile{x, y}
			if field, ok := strconv.parse_uint(f); ok {
				current_cell.pixels[iy][ix] = u8(field)
			}
		}
	}

	for i in 0 ..< 10 {
		for j in 0 ..< 10 {
			validity := is_valid_room_cell(rooms[j][i])
			if validity {
				sa.append(&cell_array, rooms[j][i])
			}
		}
	}
	return MapRoom{cells = cell_array, name = tag}
}

room_tag_as_filepath :: proc(tag: Room_Tag, extension: enum {
		CSV,
		PNG,
	}) -> string {
	switch extension {
	case .CSV:
		return fmt.tprintf("assets/ldtk/samples/simplified/%v/Main.csv", tag)
	case .PNG:
		return fmt.tprintf("assets/ldtk/samples/simplified/%v/Main.png", tag)
	}
	return ""
}
