package main

import "core:encoding/csv"
import "core:fmt"
import "core:os"
import "core:strconv"

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
	width := len(records[0]) / 16
	height := len(records) / 16


	rooms: [16][16]Cell

	for r, i in records {
		for f, j in r {
			cx: i16 = i16(j) / 16
			cy: i16 = i16(i) / 16
			position := Cell_Position{cx, cy}
			x := i16(j) - (cx * 16)
			y := i16(i) - (cy * 16)
			if field, ok := strconv.parse_uint(f); ok {
				exists := position in cells
				if !exists {
					cells[position] = Cell{}
				}
				cell := &cells[position]
				cell.tiles[y][x] = Tile(field)
			}
		}
	}
	return Room{cells = cells}
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
