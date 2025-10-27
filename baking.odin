/*
	 Logic pertaining to translating the created map into actual rooms in the game world
*/
package main

import "core:log"
import "core:math"
import "core:slice"
import "core:time"
import rl "vendor:raylib"

// streams: [dynamic]Water_Stream
volumes: [dynamic]Water_Volume
paths: [dynamic]Water_Path

bake_map :: proc(t: ^Tilemap) {
	place_tiles(t)
	log.debug("Finished placing tiles")
	generate_collision(t^)
	log.debug("Finished generating collision")
	bake_water(t^)
	log.debug("Finished baking water")
	// bake_entities()
}

reset_map :: proc(tilemap: ^Tilemap) {

	clear(&tilemap.collision_tiles)
	clear(&tilemap.entity_tiles)
	for &room, _ in rooms {
		room.placed = false
	}
}

draw_tilemap :: proc() {
	draw_colliders()
	// draw_water()
	// draw_water_streams()
	// draw_water_volumes()
}

draw_water_volumes :: proc() {
	for v in volumes {
		max := Vec3{f32(v.max.x + 1), f32(v.max.y + 1), 0}
		min := Vec3{f32(v.min.x), f32(v.min.y), 0}
		center := ((max + min) / 2)
		extents := max - min
		extents.z = 1
		rl.DrawCubeV(center, extents, {0, 50, 150, 255})
	}
}

// draw_water_paths :: proc() {
// 	for s in streams {
// 		start := position_from_tile(s.start.x, s.start.y)
// 		end := position_from_tile(s.end.x, s.end.y)
// 		center := (start + end) / 2
// 		width, height: f32
// 		color: rl.Color
// 		switch s.direction {
// 		case .North, .South:
// 			width = 16
// 			height = math.abs(start.y - end.y)
// 			color = rl.PINK
// 		case .East, .West:
// 			height = 16
// 			width = math.abs(start.x - end.x)
// 			color = rl.YELLOW
// 		}
// 		rl.DrawCubeV(extend(center, 0), {width / 2, height / 2, 1}, color)
// 	}
// }

draw_water :: proc(t: Tilemap) {
	map_height, map_width := get_tilemap_dimensions(t)
	x, y: int
	for y < map_height {
		x = 0
		for x < map_width {
			if get_static_tile(t, x, y) == .Water {
				position := Vec3{f32(x), f32(y), 0}
				rl.DrawCubeV(position, V_ONE, rl.BLUE)
			}
			x += 1
		}
		y += 1
	}
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
			rl.DrawLine3D(extend(a, 0.5), extend(b, 0.5), rl.RED)
			rl.DrawLine3D(extend(b, 0.5), extend(c, 0.5), rl.RED)
			rl.DrawLine3D(extend(c, 0.5), extend(d, 0.5), rl.RED)
			rl.DrawLine3D(extend(d, 0.5), extend(a, 0.5), rl.RED)
		}
	}
}

place_tiles :: proc(t: ^Tilemap) {
	tiles_added, entities_added: int
	for room, _ in rooms {
		if room.placed {
			for position, cell in room.cells {
				tiles, entities, exits := rotate_cell(
					cell.tiles,
					cell.entities,
					cell.exits,
					room.rotation,
				)
				for y in 0 ..< CD {
					for x in 0 ..< CD {
						cell_pos := cell_global_position(position, room.position, room.rotation)
						set_cell_exits(t, cell_pos, exits)
						raw_x := x + int(cell_pos.x * CD)
						raw_y := y + int(cell_pos.y * CD)
						tile := tiles[tile_index(x, y)]
						entity := entities[tile_index(x, y)]
						if tile != .Empty {
							set_static_tile(t, raw_x, raw_y, tile)
							tiles_added += 1
						}
						if entity != .None {


							set_entity_tile(t, raw_x, raw_y, entity)
							entities_added += 1
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

generate_collision :: proc(t: Tilemap) {
	start_time := time.now()

	map_height, map_width := get_tilemap_dimensions(t)
	wall_chains := make([dynamic]Wall_Chain, 0, 32, allocator = context.temp_allocator)
	column_segments := make(map[Tile_Position]struct {}, 32, allocator = context.temp_allocator)
	x, y: int
	// Loop through our placed walls and find adjacent wall tiles to group together for generating collision AABBs
	for y < map_height {
		x = 0
		for x < map_width {
			tile := get_static_tile(t, x, y)
			if tile == .Wall {
				chain := Wall_Chain {
					start   = x,
					end     = x,
					y_start = y,
					y_end   = y,
				}
				x += 1
				for get_static_tile(t, x, y) == .Wall && x < map_width {
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

	// Loop through our chains of joined wall tiles vertically to combine 1 length chains

	// TODO: If the perf needs it, rework to group chains of all identical width/positions so we don't get a bunch of 2 length colliders stacked on top of each other
	for y in 0 ..< map_height {
		for x in 0 ..< map_width {
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
			min = {f32(chain.start), f32(chain.y_start)},
			max = {f32(chain.end + 1), f32(chain.y_end + 1)},
		}
		append(&colliders, collider)
	}

	end_time := time.now()
	total_duration := time.duration_milliseconds(time.diff(start_time, end_time))

	if ODIN_DEBUG {
		log.debugf("Collision Generation took %v ms", total_duration)
		// log.debugf("Generated %v wall chains", len(wall_chains))
		// for chain in wall_chains {
		// 	log.debugf("%v", chain)
		// }
	}
}

// For now to keep things seperated this will be a totally seperate baking step, ideally we would iterate the tilemap as few times as possible
bake_water :: proc(t: Tilemap) {
	map_height, map_width := get_tilemap_dimensions(t)
	paths = make([dynamic]Water_Path, 0, 16)
	for y in 0 ..< map_height {
		for x in 0 ..< map_width {
			tile := get_static_tile(t, x, y)
			if tile == .Water {
				path := resolve_water_path(t, {u16(x), u16(y)}, .South)
				append(&paths, path)
			}
		}
	}
}


resolve_water_path :: proc(t: Tilemap, start: Tile_Position, direction: Direction) -> Water_Path {
	segments := make([dynamic]Water_Path_Segment, 0, 8)
	append(
		&segments,
		Water_Path_Segment{start = start, direction = direction, finished = false, length = 0},
	)

	// Bit set for easy checks if a direction is horizontal
	horizontal: bit_set[Direction] = {.East, .West}
	// Bit set for easy checks if water can pass through a tile
	water_passthrough: bit_set[Tile] = {.Empty}

	// Outer loop that is manually broken because we will be adding to a collection while iterating it
	for unfinished_segments(segments[:]) == 0 {
		for &s in segments {
			pos: [2]int = {int(start.x), int(start.y)}
			shift := shift_from_direction(direction)
			if !s.finished {
				pos += shift
				tile := get_static_tile(t, pos.x, pos.y)
				switch tile {
				case .Empty:
					s.length += 1
					if s.direction in horizontal {
						// Check if the segment should end and spawn another heading down
						if get_static_tile(t, pos.x, pos.y + 1) in water_passthrough {
							s.finished = true
							append(
								&segments,
								Water_Path_Segment {
									start = {u16(pos.x), u16(pos.y + 1)},
									direction = .South,
								},
							)
						}
					}
				case .Wall, .Door, .Water:
					s.finished = true
					// Check collision on the left and right and make segments in the clear directions
					if !(s.direction in horizontal) {
						if get_static_tile(t, pos.x - 1, pos.y - 1) in water_passthrough {
							append(
								&segments,
								Water_Path_Segment {
									start = {u16(pos.x - 1), u16(pos.y - 1)},
									direction = .West,
								},
							)
						}
						if get_static_tile(t, pos.x + 1, pos.y) in water_passthrough {
							append(
								&segments,
								Water_Path_Segment {
									start = {u16(pos.x + 1), u16(pos.y - 1)},
									direction = .East,
								},
							)
						}
					}
					continue
				case .OneWay:
				}
			}
		}
	}
	return Water_Path{segments = segments}
}

shift_from_direction :: proc(d: Direction) -> [2]int {
	shift: [2]int
	switch d {
	case .North:
		shift = {0, -1}
	case .South:
		shift = {0, 1}
	case .East:
		shift = {1, 0}
	case .West:
		shift = {-1, 0}
	}
	return shift
}

Water_Path_Segment :: struct {
	start:     Tile_Position,
	length:    int,
	direction: Direction,
	finished:  bool,
}

unfinished_segments :: proc(segments: []Water_Path_Segment) -> int {
	count: int
	for s in segments {
		if !s.finished {
			count += 1
		}
	}
	return count
}

Water_Path :: struct {
	segments: [dynamic]Water_Path_Segment,
}

Water_Volume :: struct {
	min: Tile_Position,
	max: Tile_Position,
}

Tile_Range :: struct {
	min: u16,
	max: u16,
	y:   u16,
}

// range_from_stream :: proc(s: Water_Stream) -> Tile_Range {
// 	return Tile_Range {
// 		min = math.min(s.start.x, s.end.x),
// 		max = math.max(s.start.x, s.end.x),
// 		y = s.start.y,
// 	}
// }

// range_overlap :: proc(a, b: Tile_Range) -> bool {
// 	return a.min <= b.max && b.min <= a.max && a.y == b.y
// }

// bake_entities :: proc() {
// 	// Bake entities from the bottom up to calculate starting position based on physics rules
// 	for y := (TILE_COUNT * CELL_COUNT) - 1; y > 0; y -= 1 {
// 		for x in 0 ..< TILE_COUNT * CELL_COUNT {
// 			entity := initial_entity_map[global_index(x, y)]
// 			switch entity {
// 			case .None:
// 				continue
// 			case .Box:
// 				resolve_box({u16(x), u16(y)})
// 			}
// 		}
// 	}
// }

// resolve_box :: proc(starting_pos: Tile_Position) {
// 	x, y := int(starting_pos.x), int(starting_pos.y)

// 	last_empty_y := y
// 	for y < TILE_COUNT * CELL_COUNT {
// 		tile := tilemap[global_index(x, y)]
// 		entity := initial_entity_map[global_index(x, y)]
// 		if tile == .Wall || entity == .Box {
// 			initial_entity_map[global_index(starting_pos.x, starting_pos.y)] = .None
// 			initial_entity_map[global_index(x, last_empty_y)] = .Box
// 			break
// 		} else {
// 			last_empty_y = y
// 		}
// 		y += 1
// 	}
// }

/////// OLD water logic
// bake_water_old :: proc(t: ^Tilemap, update_tilemap: bool) {
// 	map_height, map_width := get_tilemap_dimensions(t)
// 	streams = make([dynamic]Water_Stream, 0, 16)
// 	for y in 0 ..< map_height {
// 		for x in 0 ..< map_width {
// 			tile := tilemap[global_index(x, y)]
// 			if tile == .Water {
// 				streams_from_tile := resolve_water_tile(t, {u16(x), u16(y)}, update_tilemap)
// 				append_elems(&streams, ..streams_from_tile[:])
// 			}
// 		}
// 	}
// 	log.debug("Finished resolvings streams")
// 	volumes = generate_volumes(streams[:])
// 	if ODIN_DEBUG {
// 		log.debug("WATER STREAMS\n")
// 		for s in streams {
// 			log.debugf(
// 				"--------\nstart: %v, end: %v\ndirection: %v\n--------\n",
// 				s.start,
// 				s.end,
// 				s.direction,
// 			)
// 		}
// 		log.debug("--END STREAMS--\n")

// 		log.debug("WATER VOLUMES\n")
// 		for v in volumes {
// 			log.debugf("-------------\n%v\n-------------------------\n", v)
// 		}
// 		log.debug("--END VOLUMES--\n")
// 	}
// }

// resolve_water_tile_old :: proc(
// 	t: ^Tilemap,
// 	start: Tile_Position,
// 	update_tilemap: bool,
// ) -> [dynamic]Water_Stream {
// 	streams := make([dynamic]Water_Stream, 0, 8, allocator = context.temp_allocator)
// 	append(&streams, Water_Stream{start = start, direction = .South})
// 	should_continue := true
// 	iterations: int
// 	for should_continue {
// 		for &stream in streams[:] {
// 			if !stream.finished {
// 				if iterations > 50 {
// 					log.debug("Hit 50 iterations on a stream, breaking")
// 					should_continue = false
// 				}
// 				child_streams := resolve_water_stream(&stream, update_tilemap)
// 				append_elems(&streams, ..child_streams[:])
// 			}
// 			iterations += 1
// 		}
// 		unfinished := unfinished_streams(streams[:])
// 		should_continue = unfinished > 0
// 	}
// 	return streams
// }


// resolve_water_stream_old :: proc(
// 	stream: ^Water_Stream,
// 	update_tilemap: bool,
// ) -> [dynamic]Water_Stream {
// 	out_streams := make([dynamic]Water_Stream, 0, 2, allocator = context.temp_allocator)
// 	x, y := stream.start.x, stream.start.y
// 	#partial switch stream.direction {
// 	case .South:
// 		y += 1
// 	case .East:
// 		x += 1
// 	case .West:
// 		x -= 1
// 	}
// 	iterations: int
// 	#partial switch stream.direction {
// 	case .South:
// 		last_empty_y: u16 = y
// 		for y < CELL_COUNT * TILE_COUNT && !stream.finished && iterations < 50 {
// 			tile := tilemap[global_index(x, y)]
// 			#partial switch tile {
// 			case .Water:
// 				stream.finished = true
// 				stream.reason = .Water
// 				stream.end = Tile_Position{x, last_empty_y}
// 			case .Wall:
// 				stream.finished = true
// 				stream.reason = .WallDrop
// 				stream.end = Tile_Position{x, last_empty_y}
// 				if tilemap[global_index(x - 1, last_empty_y)] == .Empty {
// 					append(
// 						&out_streams,
// 						Water_Stream{start = {x, last_empty_y}, direction = .West},
// 					)
// 				}
// 				if tilemap[global_index(x + 1, last_empty_y)] == .Empty {
// 					append(
// 						&out_streams,
// 						Water_Stream{start = {x, last_empty_y}, direction = .East},
// 					)
// 				}
// 			case .Empty:
// 				last_empty_y = y
// 				if update_tilemap {tilemap[global_index(x, y)] = .Water}
// 			}
// 			y += 1
// 			iterations += 1
// 		}
// 	case .West:
// 		last_empty_x: u16
// 		for x > 0 && !stream.finished && iterations < 50 {
// 			tile := tilemap[global_index(x, y)]
// 			#partial switch tile {
// 			// case .Water:
// 			// 	stream.finished = true
// 			// 	stream.reason = .Water
// 			// 	stream.end = Tile_Position{last_empty_x, y}
// 			case .Wall:
// 				stream.finished = true
// 				stream.reason = .Wall
// 				stream.end = Tile_Position{last_empty_x, y}
// 			case .Empty, .Water:
// 				last_empty_x = x
// 				if update_tilemap {tilemap[global_index(x, y)] = .Water}
// 				if tilemap[global_index(x, y + 1)] == .Empty {
// 					stream.finished = true
// 					stream.reason = .Drop
// 					stream.end = Tile_Position{x, y}
// 					append(&out_streams, Water_Stream{start = {x, y}, direction = .South})
// 				}
// 			}
// 			x -= 1
// 			iterations += 1
// 		}
// 	case .East:
// 		last_empty_x: u16
// 		for x < CELL_COUNT * TILE_COUNT && !stream.finished && iterations < 50 {
// 			tile := tilemap[global_index(x, y)]
// 			#partial switch tile {
// 			// case .Water:
// 			// 	stream.finished = true
// 			// 	stream.reason = .Water
// 			// 	stream.end = Tile_Position{last_empty_x, y}
// 			case .Wall:
// 				stream.finished = true
// 				stream.reason = .Wall
// 				stream.end = Tile_Position{last_empty_x, y}
// 			case .Empty, .Water:
// 				last_empty_x = x
// 				if update_tilemap {tilemap[global_index(x, y)] = .Water}
// 				if tilemap[global_index(x, y + 1)] == .Empty {
// 					stream.finished = true
// 					stream.reason = .Drop
// 					stream.end = Tile_Position{x, y}
// 					append(&out_streams, Water_Stream{start = {x, y}, direction = .South})
// 				}
// 			}
// 			x += 1
// 			iterations += 1
// 		}
// 	}
// 	return out_streams
// }

// unfinished_streams :: proc(streams: []Water_Stream) -> int {
// 	count: int
// 	for s in streams {
// 		if !s.finished {
// 			count += 1
// 		}
// 	}
// 	return count
// }

// Water_Stream :: struct {
// 	start:     Tile_Position,
// 	end:       Tile_Position,
// 	direction: Direction,
// 	finished:  bool,
// 	reason:    enum {
// 		Wall,
// 		Water,
// 		Drop,
// 		WallDrop,
// 	},
// }

// generate_volumes_old :: proc(streams: []Water_Stream) -> [dynamic]Water_Volume {
// 	ranges := make([dynamic]Tile_Range, 0, 8, allocator = context.temp_allocator)
// 	checked_heights := make([dynamic]u16, 0, 4, allocator = context.allocator)
// 	volumes := make([dynamic]Water_Volume, 0, 4)
// 	for s in streams {
// 		if (s.direction == .East || s.direction == .West) &&
// 		   (s.reason == .Water || s.reason == .Wall) {

// 			append(&ranges, range_from_stream(s))
// 		}
// 	}

// 	if ODIN_DEBUG {
// 		log.debugf("Ranges: %v\n", ranges)
// 	}
// 	for a, i in ranges {
// 		already_parsed := slice.contains(checked_heights[:], a.y)
// 		if !already_parsed {
// 			current := a
// 			append(&checked_heights, a.y)
// 			for b, j in ranges {
// 				if i == j do continue
// 				if range_overlap(a, b) {
// 					current.min = math.min(a.min, b.min)
// 					current.max = math.max(a.max, b.max)
// 				}
// 			}
// 			left_height, right_height: u16
// 			if current.min > 1 {
// 				for k in 0 ..< 5 {
// 					if tilemap[global_index(current.min - 1, current.y - u16(i + 1))] != .Empty {
// 						left_height += 1
// 					} else {
// 						log.infof(
// 							"Breaking left wall for [%v,%v : %v] at %v\n",
// 							current.min,
// 							current.max,
// 							current.y,
// 							left_height,
// 						)
// 						break
// 					}
// 				}
// 			} else {
// 				left_height = 1
// 			}
// 			if current.max < TILE_COUNT * CELL_COUNT {
// 				for k in 0 ..< 4 {
// 					if tilemap[global_index(current.max + 1, current.y - u16(i + 1))] != .Empty {
// 						right_height += 1
// 					} else {
// 						log.infof(
// 							"Breaking right wall for [%v,%v : %v] at %v\n",
// 							current.min,
// 							current.max,
// 							current.y,
// 							right_height,
// 						)
// 						break
// 					}
// 				}
// 			} else {
// 				right_height = 1
// 			}
// 			append(
// 				&volumes,
// 				Water_Volume {
// 					min = {current.min, current.y - (1 + math.min(left_height, right_height))},
// 					max = {current.max, current.y},
// 				},
// 			)
// 		}
// 	}
// 	return volumes
// }
