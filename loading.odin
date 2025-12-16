/*
	 Logic pertaining to loading assets on startup
*/
package main

import "core:encoding/csv"
import "core:fmt"
import "core:log"
import "core:os"
import "core:strconv"
import rl "vendor:raylib"

SHADER_LOC_VIEW :: 12

Assets :: struct {
	rooms:            [Room_Tag]Room,
	ui_texture_atlas: [Ui_Texture_Tag]rl.Texture,
	gameplay_texture: rl.RenderTexture,
	map_texture:      rl.RenderTexture,
	lighting_shader:  rl.Shader,
}

load_assets :: proc() {
	assets.rooms = load_rooms()
	assets.ui_texture_atlas = load_ui_textures()
	assets.map_texture = rl.LoadRenderTexture(WINDOW_HEIGHT, WINDOW_HEIGHT)
	assets.gameplay_texture = rl.LoadRenderTexture(WINDOW_HEIGHT, WINDOW_HEIGHT)
	lighting_shader := rl.LoadShader("assets/shaders/lighting.vs", "assets/shaders/lighting.fs")

	lighting_shader.locs[SHADER_LOC_VIEW] = rl.GetShaderLocation(lighting_shader, "viewPos")
	assets.lighting_shader = lighting_shader
}

load_rooms :: proc() -> [Room_Tag]Room {
	return {
		.None = Room{},
		.A = read_room(.A),
		.B = read_room(.B),
		.C = read_room(.C),
		.D = read_room(.D),
		.E = read_room(.E),
	}
}

read_room :: proc(tag: Room_Tag) -> Room {
	cells := make(map[Cell_Position]Cell, 8)
	write_cell_tile_data(&cells, tag)
	write_cell_entity_data(&cells, tag)
	write_cell_exit_data(&cells, tag)
	room := Room {
		cells = cells,
	}
	parse_room_stats(&room, tag)
	return room
}

write_cell_tile_data :: proc(cells: ^map[Cell_Position]Cell, tag: Room_Tag) {
	filename := room_tag_as_filepath(tag, .Main)
	r: csv.Reader
	r.trim_leading_space = true
	defer csv.reader_destroy(&r)


	data, ok := os.read_entire_file(filename)
	if ok {
		csv.reader_init_with_string(&r, string(data))
	} else {
		log.errorf("Unable to open file: %v", filename)
	}
	defer delete(data)

	records, err := csv.read_all(&r)
	if err != nil do log.errorf("Failed to parse CSV file for %v\nErr: %v", filename, err)

	defer {
		for rec in records {
			delete(rec)
		}
		delete(records)
	}

	for r, i in records {
		for f, j in r {
			cx: i16 = i16(j) / CD
			cy: i16 = i16(i) / CD
			position := Cell_Position{cx, cy}
			x := i16(j) - (cx * CD)
			y := i16(i) - (cy * CD)
			if field, field_ok := strconv.parse_uint(f); field_ok {
				value := Tile(field)
				if value != .Empty {
					exists := position in cells
					if !exists {
						cells[position] = Cell{}
					}
					cell := &cells[position]
					cell.tiles[tile_index(x, y)] = value
				}
			}
		}
	}
}

write_cell_entity_data :: proc(cells: ^map[Cell_Position]Cell, tag: Room_Tag) {
	filename := room_tag_as_filepath(tag, .Room_Entities)
	r: csv.Reader
	r.trim_leading_space = true
	defer csv.reader_destroy(&r)


	data, ok := os.read_entire_file(filename)
	if ok {
		csv.reader_init_with_string(&r, string(data))
	} else {
		log.errorf("Unable to open file: %v", filename)
	}
	defer delete(data)

	records, err := csv.read_all(&r)
	if err != nil do log.errorf("Failed to parse CSV file for %v\nErr: %v", filename, err)

	defer {
		for rec in records {
			delete(rec)
		}
		delete(records)
	}

	for r, i in records {
		for f, j in r {
			cx: i16 = i16(j) / CD
			cy: i16 = i16(i) / CD
			position := Cell_Position{cx, cy}
			x := i16(j) - (cx * CD)
			y := i16(i) - (cy * CD)
			if field, field_ok := strconv.parse_uint(f); field_ok {
				value := Entity_Tag(field)
				if value != .None {
					exists := position in cells
					if !exists {
						cells[position] = Cell{}
					}
					cell := &cells[position]
					cell.entities[tile_index(x, y)] = value
				}
			}
		}
	}
}

write_cell_exit_data :: proc(cells: ^map[Cell_Position]Cell, tag: Room_Tag) {
	filename := room_tag_as_filepath(tag, .Exits)
	r: csv.Reader
	r.trim_leading_space = true
	defer csv.reader_destroy(&r)


	data, ok := os.read_entire_file(filename)
	if ok {
		csv.reader_init_with_string(&r, string(data))
	} else {
		log.errorf("Unable to open file: %v", filename)
	}
	defer delete(data)

	records, err := csv.read_all(&r)
	if err != nil do log.errorf("Failed to parse CSV file for %v\nErr: %v", filename, err)

	defer {
		for rec in records {
			delete(rec)
		}
		delete(records)
	}

	for r, i in records {
		for f, j in r {
			if field, field_ok := strconv.parse_int(f); field_ok {
				if field != 0 {
					exits := exits_from_int_grid(field)
					position := Cell_Position{i16(j), i16(i)}
					cell := cells[position]
					cell.exits = exits
					cells[position] = cell
				}
			}
		}
	}
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

room_tag_as_filepath :: proc(tag: Room_Tag, map_type: enum {
		Main,
		Exits,
		Room_Entities,
	}) -> string {
	return fmt.tprintf("assets/ldtk/renchi/simplified/%v/%v.csv", tag, map_type)
}

exits_from_int_grid :: proc(value: int) -> bit_set[Direction] {
	switch value {
	case 1:
		return {.North}
	case 2:
		return {.South}
	case 3:
		return {.East}
	case 4:
		return {.West}
	case 5:
		return {.North, .East}
	case 6:
		return {.North, .West}
	case 7:
		return {.North, .South}
	case 8:
		return {.South, .East}
	case 9:
		return {.South, .West}
	case 10:
		return {.East, .West}
	case 11:
		return {.North, .East, .West}
	case 12:
		return {.South, .East, .West}
	case 13:
		return {.North, .South, .East}
	case 14:
		return {.North, .South, .West}
	case 15:
		return {.North, .South, .East, .West}
	}
	return bit_set[Direction]{}
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
