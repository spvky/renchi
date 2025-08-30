package main

import "core:log"
import "core:math"
import "core:time"
import rl "vendor:raylib"

bake_map :: proc() {
	place_tiles()
	generate_collision()
}

reset_map :: proc() {
	tilemap = [65536]Tile{}
	for &room, _ in rooms {
		room.placed = false
	}
}

draw_tilemap :: proc() {
	// for y in 0 ..< 256 {
	// 	for x in 0 ..< 256 {
	// 		tile := tilemap[global_index(x, y)]
	// 		if tile == .Wall {
	// 			rl.DrawCircleV({f32(x) * 2, f32(y) * 2}, 1, rl.BLACK)
	// 		}
	// 	}
	// }
	draw_colliders()
}

draw_colliders :: proc() {
	for collider in colliders {
		a: Vec2 = collider.min
		b: Vec2 = {collider.max.x, collider.min.y}
		c: Vec2 = collider.max
		d: Vec2 = {collider.min.x, collider.max.y}

		rl.DrawLineEx(a, b, 2, rl.RED)
		rl.DrawLineEx(b, c, 2, rl.RED)
		rl.DrawLineEx(c, d, 2, rl.RED)
		rl.DrawLineEx(d, a, 2, rl.RED)
	}
}

place_tiles :: proc() {
	tiles_added: int
	for room, tag in rooms {
		if room.placed {
			for position, cell in room.cells {
				tiles := rotate_cell(cell.tiles, room.rotation)
				for y in 0 ..< 16 {
					for x in 0 ..< 16 {
						cell_pos := cell_global_position(position, room.position, room.rotation)

						raw_x := x + int(cell_pos.x * 16)
						raw_y := y + int(cell_pos.y * 16)
						tile := tiles[tile_index(x, y)]
						if tile != .Empty {
							tilemap[global_index(raw_x, raw_y)] = tile
							tiles_added += 1
						}
					}
				}
			}
		}
	}
}

Wall_Chain :: struct {
	y_start: int,
	y_end:   int,
	start:   int,
	end:     int,
}

generate_collision :: proc() {
	start_time := time.now()
	wall_chains := make([dynamic]Wall_Chain, 0, 32, allocator = context.temp_allocator)
	column_segments := make(map[Tile_Position]struct {}, 32, allocator = context.temp_allocator)
	x, y: int
	for y < 256 {
		x = 0
		for x < 256 {
			tile := tilemap[global_index(x, y)]
			if tile == .Wall {
				chain := Wall_Chain {
					start   = x,
					end     = x,
					y_start = y,
					y_end   = y,
				}
				x += 1
				for tilemap[global_index(x, y)] == .Wall && x < 256 {
					chain.end = x
					x += 1
				}
				if chain.end == chain.start {
					column_segments[{u16(chain.start), u16(chain.y_start)}] = {}
				} else {
					append(&wall_chains, chain)
				}
			}
			x += 1
		}
		y += 1
	}

	for y in 0 ..< 256 {
		for x in 0 ..< 256 {
			position := Tile_Position{u16(x), u16(y)}
			if _, column_exists := column_segments[position]; column_exists {
				chain := Wall_Chain {
					start   = int(position.x),
					end     = int(position.x),
					y_start = int(position.y),
					y_end   = int(position.y),
				}
				offset: u16
				still_searching := true
				for still_searching {
					offset += 1
					search_position := Tile_Position{position.x, position.y + offset}
					if _, position_exists := column_segments[search_position]; position_exists {
						chain.y_end = int(search_position.y)
						delete_key(&column_segments, search_position)
					} else {
						still_searching = false
						append(&wall_chains, chain)
					}
				}
			}
		}
	}

	tile_size: f32 = 2

	for chain in wall_chains {
		collider := Collider {
			min = {f32(chain.start) * tile_size, f32(chain.y_start) * tile_size},
			max = {f32(chain.end + 1) * tile_size, f32(chain.y_end + 1) * tile_size},
		}
		append(&colliders, collider)
	}

	end_time := time.now()
	total_duration := time.duration_milliseconds(time.diff(start_time, end_time))

	log.debugf("Collision Generation took %v ms", total_duration)
	log.debugf("Generated %v wall chains", len(wall_chains))
	for chain in wall_chains {
		log.debugf("%v", chain)
	}
}
