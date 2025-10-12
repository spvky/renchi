/*
	 Logic pertaining to translating the created map into actual rooms in the game world
*/
package main

import "core:log"
import "core:time"
import rl "vendor:raylib"

bake_map :: proc() {
	place_tiles()
	generate_collision()
}

reset_map :: proc() {
	tilemap = [(TILE_COUNT * TILE_COUNT) * (CELL_COUNT * CELL_COUNT)]Tile{}
	for &room, _ in rooms {
		room.placed = false
	}
}

draw_tilemap :: proc() {
	draw_colliders()
}

draw_colliders :: proc() {
	for collider in colliders {
		a: Vec2 = collider.min
		b: Vec2 = {collider.max.x, collider.min.y}
		c: Vec2 = collider.max
		d: Vec2 = {collider.min.x, collider.max.y}
		center := extend((a + b + c + d) / 4, 0)
		size := Vec3{collider.max.x - collider.min.x, collider.max.y - collider.min.y, 1}
		rl.DrawCubeV(center, size, rl.GRAY)
		if ODIN_DEBUG {
			rl.DrawLine3D(extend(a, -0.5), extend(b, -0.5), rl.RED)
			rl.DrawLine3D(extend(b, -0.5), extend(c, -0.5), rl.RED)
			rl.DrawLine3D(extend(c, -0.5), extend(d, -0.5), rl.RED)
			rl.DrawLine3D(extend(d, -0.5), extend(a, -0.5), rl.RED)
			rl.DrawLine3D(extend(a, 0.5), extend(b, 0.5), rl.RED)
			rl.DrawLine3D(extend(b, 0.5), extend(c, 0.5), rl.RED)
			rl.DrawLine3D(extend(c, 0.5), extend(d, 0.5), rl.RED)
			rl.DrawLine3D(extend(d, 0.5), extend(a, 0.5), rl.RED)
			rl.DrawLine3D(extend(a, 0.5), extend(a, -0.5), rl.RED)
			rl.DrawLine3D(extend(b, 0.5), extend(b, -0.5), rl.RED)
			rl.DrawLine3D(extend(c, 0.5), extend(c, -0.5), rl.RED)
			rl.DrawLine3D(extend(d, 0.5), extend(d, -0.5), rl.RED)
		}
	}
}

place_tiles :: proc() {
	tiles_added: int
	for room, _ in rooms {
		if room.placed {
			for position, cell in room.cells {
				tiles, exits := rotate_cell(cell.tiles, cell.exits, room.rotation)
				for y in 0 ..< TILE_COUNT {
					for x in 0 ..< TILE_COUNT {
						cell_pos := cell_global_position(position, room.position, room.rotation)
						exit_map[cell_index(cell_pos.x, cell_pos.y)] = exits
						raw_x := x + int(cell_pos.x * TILE_COUNT)
						raw_y := y + int(cell_pos.y * TILE_COUNT)
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
	for y < CELL_COUNT * TILE_COUNT {
		x = 0
		for x < CELL_COUNT * TILE_COUNT {
			tile := tilemap[global_index(x, y)]
			if tile == .Wall {
				chain := Wall_Chain {
					start   = x,
					end     = x,
					y_start = y,
					y_end   = y,
				}
				x += 1
				for tilemap[global_index(x, y)] == .Wall && x < TILE_COUNT * TILE_COUNT {
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

	for y in 0 ..< TILE_COUNT * TILE_COUNT {
		for x in 0 ..< TILE_COUNT * TILE_COUNT {
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

	for chain in wall_chains {
		collider := Collider {
			min = {f32(chain.start) * TILE_SIZE, f32(chain.y_start) * TILE_SIZE},
			max = {f32(chain.end + 1) * TILE_SIZE, f32(chain.y_end + 1) * TILE_SIZE},
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

calculate_water_path :: proc(start: Tile_Position) -> [dynamic]Water_Stream {
	total_streams: int
	streams := make([dynamic]Water_Stream, 0, 8, allocator = context.temp_allocator)
	append(&streams, Water_Stream{start = start, direction = .South})
	total_streams += 1
	for has_unfinished_streams(streams[:]) {
		stream_loop: for i in 0 ..< total_streams {
			if !streams[i].finished {
				current_stream := &streams[i]
				x, y := start.x, start.y
				#partial switch current_stream.direction {
				case .South:
					last_empty_y: u16
					for y < CELL_COUNT * TILE_COUNT {
						tile := tilemap[global_index(x, y)]
						#partial switch tile {
						case .Wall:
							current_stream.finished = true
							current_stream.end = Tile_Position{x, last_empty_y}
							append_elems(
								&streams,
								Water_Stream{start = {x, last_empty_y}, direction = .East},
								Water_Stream{start = {x, last_empty_y}, direction = .West},
							)
							continue stream_loop
						case .Empty:
							last_empty_y = y
						}
						y += 1
					}
				case .West:
					last_empty_x: u16
					for x >= 0 {
						tile := tilemap[global_index(x, y)]
						#partial switch tile {
						case .Wall:
							current_stream.finished = true
							current_stream.end = Tile_Position{last_empty_x, y}
							continue stream_loop
						case .Empty:
							last_empty_x = x
							if tilemap[global_index(x, y + 1)] == .Empty {
								current_stream.finished = true
								current_stream.end = Tile_Position{x, y}
								append(&streams, Water_Stream{start = {x, y}, direction = .South})
							}
						}
						x -= 1
					}
				case .East:
					last_empty_x: u16
					for x < CELL_COUNT * TILE_COUNT {
						tile := tilemap[global_index(x, y)]
						#partial switch tile {
						case .Wall:
							current_stream.finished = true
							current_stream.end = Tile_Position{last_empty_x, y}
							continue stream_loop
						case .Empty:
							last_empty_x = x
							if tilemap[global_index(x, y + 1)] == .Empty {
								current_stream.finished = true
								current_stream.end = Tile_Position{x, y}
								append(&streams, Water_Stream{start = {x, y}, direction = .South})
							}
						}
						x += 1
					}
				}
			}
		}
	}
	return streams
}

has_unfinished_streams :: proc(streams: []Water_Stream) -> bool {
	for s in streams {
		if !s.finished {
			return true
		}
	}
	return false
}

calculate_water_stream :: proc(start: Tile_Position, direction: Direction) {
	// Continue in direction
	// if direction is south:
	// // create new streams heading east and west when you hit the ground
	// if direction is east/west
	// // when the tile below is empty, create a stream heading south
}

Water_Stream :: struct {
	start:     Tile_Position,
	end:       Tile_Position,
	direction: Direction,
	finished:  bool,
}
