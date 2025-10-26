/*
	 Logic pertaining to translating the created map into actual rooms in the game world
*/
package main

import "core:log"
import "core:math"
import "core:slice"
import "core:time"
import rl "vendor:raylib"

streams: [dynamic]Water_Stream
volumes: [dynamic]Water_Volume

bake_map :: proc() {
	place_tiles()
	log.debug("Finished placing tiles")
	generate_collision()
	log.debug("Finished generating collision")
	bake_water(update_tilemap = true)
	log.debug("Finished baking water")
	bake_entities()
}

reset_map :: proc() {
	tilemap = [(TILE_COUNT * TILE_COUNT) * (CELL_COUNT * CELL_COUNT)]Tile{}
	for &room, _ in rooms {
		room.placed = false
	}
}

draw_tilemap :: proc() {
	draw_colliders()
	// draw_water()
	draw_water_streams()
	// draw_water_volumes()
}

draw_water_volumes :: proc() {
	for v in volumes {
		max := Vec3{f32(v.max.x + 1), f32(v.max.y + 1), 0} * TILE_SIZE
		min := Vec3{f32(v.min.x), f32(v.min.y), 0} * TILE_SIZE
		center := ((max + min) / 2)
		extents := max - min
		extents.z = 1
		rl.DrawCubeV(center, extents, {0, 50, 150, 255})
	}
}

draw_water_streams :: proc() {
	for s in streams {
		start := position_from_tile(s.start.x, s.start.y)
		end := position_from_tile(s.end.x, s.end.y)
		center := (start + end) / 2
		width, height: f32
		color: rl.Color
		switch s.direction {
		case .North, .South:
			width = 16
			height = math.abs(start.y - end.y)
			color = rl.PINK
		case .East, .West:
			height = 16
			width = math.abs(start.x - end.x)
			color = rl.YELLOW
		}
		rl.DrawCubeV(extend(center, 0), {width / 2, height / 2, 1}, color)
	}
}

draw_water :: proc() {
	x, y: int
	for y < CELL_COUNT * TILE_COUNT {
		x = 0
		for x < CELL_COUNT * TILE_COUNT {
			if tilemap[global_index(x, y)] == .Water {
				// position := Vec3{f32(x) * TILE_SIZE, f32(y) * TILE_SIZE, 0}
				// offset := Vec3{8, 8, 0}
				position := extend(position_from_tile(x, y), 0)
				rl.DrawCubeV(position, {16, 16, 16}, rl.BLUE)
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
				for y in 0 ..< TILE_COUNT {
					for x in 0 ..< TILE_COUNT {
						cell_pos := cell_global_position(position, room.position, room.rotation)
						exit_map[cell_index(cell_pos.x, cell_pos.y)] = exits
						raw_x := x + int(cell_pos.x * TILE_COUNT)
						raw_y := y + int(cell_pos.y * TILE_COUNT)
						tile := tiles[tile_index(x, y)]
						entity := entities[tile_index(x, y)]
						if tile != .Empty {
							tilemap[global_index(raw_x, raw_y)] = tile
							tiles_added += 1
						}
						if entity != .None {
							initial_entity_map[global_index(raw_x, raw_y)] = entity
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

	if ODIN_DEBUG {
		log.debugf("Collision Generation took %v ms", total_duration)
		log.debugf("Generated %v wall chains", len(wall_chains))
		for chain in wall_chains {
			log.debugf("%v", chain)
		}
	}
}

// For now to keep things seperated this will be a totally seperate baking step, ideally we would iterate the tilemap as few times as possible
bake_water :: proc(update_tilemap: bool) {
	streams = make([dynamic]Water_Stream, 0, 16)
	for y in 0 ..< TILE_COUNT * CELL_COUNT {
		for x in 0 ..< TILE_COUNT * CELL_COUNT {
			tile := tilemap[global_index(x, y)]
			if tile == .Water {
				streams_from_tile := resolve_water_tile({u16(x), u16(y)}, update_tilemap)
				append_elems(&streams, ..streams_from_tile[:])
			}
		}
	}
	log.debug("Finished resolvings streams")
	volumes = generate_volumes(streams[:])
	if ODIN_DEBUG {
		log.debug("WATER STREAMS\n")
		for s in streams {
			log.debugf(
				"--------\nstart: %v, end: %v\ndirection: %v\n--------\n",
				s.start,
				s.end,
				s.direction,
			)
		}
		log.debug("--END STREAMS--\n")

		log.debug("WATER VOLUMES\n")
		for v in volumes {
			log.debugf("-------------\n%v\n-------------------------\n", v)
		}
		log.debug("--END VOLUMES--\n")
	}
}

generate_volumes :: proc(streams: []Water_Stream) -> [dynamic]Water_Volume {
	ranges := make([dynamic]Tile_Range, 0, 8, allocator = context.temp_allocator)
	checked_heights := make([dynamic]u16, 0, 4, allocator = context.allocator)
	volumes := make([dynamic]Water_Volume, 0, 4)
	for s in streams {
		if (s.direction == .East || s.direction == .West) &&
		   (s.reason == .Water || s.reason == .Wall) {

			append(&ranges, range_from_stream(s))
		}
	}

	if ODIN_DEBUG {
		log.debugf("Ranges: %v\n", ranges)
	}
	for a, i in ranges {
		already_parsed := slice.contains(checked_heights[:], a.y)
		if !already_parsed {
			current := a
			append(&checked_heights, a.y)
			for b, j in ranges {
				if i == j do continue
				if range_overlap(a, b) {
					current.min = math.min(a.min, b.min)
					current.max = math.max(a.max, b.max)
				}
			}
			left_height, right_height: u16
			if current.min > 1 {
				for k in 0 ..< 5 {
					if tilemap[global_index(current.min - 1, current.y - u16(i + 1))] != .Empty {
						left_height += 1
					} else {
						log.infof(
							"Breaking left wall for [%v,%v : %v] at %v\n",
							current.min,
							current.max,
							current.y,
							left_height,
						)
						break
					}
				}
			} else {
				left_height = 1
			}
			if current.max < TILE_COUNT * CELL_COUNT {
				for k in 0 ..< 4 {
					if tilemap[global_index(current.max + 1, current.y - u16(i + 1))] != .Empty {
						right_height += 1
					} else {
						log.infof(
							"Breaking right wall for [%v,%v : %v] at %v\n",
							current.min,
							current.max,
							current.y,
							right_height,
						)
						break
					}
				}
			} else {
				right_height = 1
			}
			append(
				&volumes,
				Water_Volume {
					min = {current.min, current.y - (1 + math.min(left_height, right_height))},
					max = {current.max, current.y},
				},
			)
		}
	}
	return volumes
}

resolve_water_tile :: proc(start: Tile_Position, update_tilemap: bool) -> [dynamic]Water_Stream {
	streams := make([dynamic]Water_Stream, 0, 8, allocator = context.temp_allocator)
	append(&streams, Water_Stream{start = start, direction = .South})
	should_continue := true
	iterations: int
	for should_continue {
		for &stream in streams[:] {
			if !stream.finished {
				if iterations > 50 {
					log.debug("Hit 50 iterations on a stream, breaking")
					should_continue = false
				}
				child_streams := resolve_water_stream(&stream, update_tilemap)
				append_elems(&streams, ..child_streams[:])
			}
			iterations += 1
		}
		unfinished := unfinished_streams(streams[:])
		should_continue = unfinished > 0
	}
	return streams
}

resolve_water_stream_new :: proc(start: Tile_Position, direction: Direction) -> Water_Path {
	segments := make([dynamic]Water_Path_Segment, 0, 8)
	append(&segments, Water_Path_Segment{start = start, direction = direction})

	// Bit set for easy checks if a direction is horizontal
	horizontal: bit_set[Direction] = {.East, .West}
	// Bit set for easy checks if water can pass through a tile
	water_passthrough: bit_set[Tile] = {.Empty}

	// Outer loop that is manually broken because we will be adding to a collection while iterating it
	for {
		for &s in segments {
			pos: [2]int = {int(start.x), int(start.y)}
			shift := shift_from_direction(direction)
			for !s.finished {
				pos += shift
				tile := tilemap[global_index(pos.x, pos.y)]
				switch tile {
				case .Empty:
					s.length += 1
					if s.direction in horizontal {
						// Check if the segment should end and spawn another heading down
						if tilemap[global_index(pos.x, pos.y + 1)] in water_passthrough {
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
					if !(s.direction in horizontal) {
						if tilemap[global_index(pos.x - 1, pos.y - 1)] in water_passthrough {
							append(
								&segments,
								Water_Path_Segment {
									start = {u16(pos.x - 1), u16(pos.y - 1)},
									direction = .West,
								},
							)
						}
						if tilemap[global_index(pos.x + 1, pos.y)] in water_passthrough {
							append(
								&segments,
								Water_Path_Segment {
									start = {u16(pos.x + 1), u16(pos.y - 1)},
									direction = .East,
								},
							)
						}
						// check collision on the left and right and make segments in the clear directions
					}
					break
				case .OneWay:
				}
			}
		}
		if unfinished_segments(segments[:]) == 0 do break
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

resolve_water_stream :: proc(
	stream: ^Water_Stream,
	update_tilemap: bool,
) -> [dynamic]Water_Stream {
	out_streams := make([dynamic]Water_Stream, 0, 2, allocator = context.temp_allocator)
	x, y := stream.start.x, stream.start.y
	#partial switch stream.direction {
	case .South:
		y += 1
	case .East:
		x += 1
	case .West:
		x -= 1
	}
	iterations: int
	#partial switch stream.direction {
	case .South:
		last_empty_y: u16 = y
		for y < CELL_COUNT * TILE_COUNT && !stream.finished && iterations < 50 {
			tile := tilemap[global_index(x, y)]
			#partial switch tile {
			case .Water:
				stream.finished = true
				stream.reason = .Water
				stream.end = Tile_Position{x, last_empty_y}
			case .Wall:
				stream.finished = true
				stream.reason = .WallDrop
				stream.end = Tile_Position{x, last_empty_y}
				if tilemap[global_index(x - 1, last_empty_y)] == .Empty {
					append(
						&out_streams,
						Water_Stream{start = {x, last_empty_y}, direction = .West},
					)
				}
				if tilemap[global_index(x + 1, last_empty_y)] == .Empty {
					append(
						&out_streams,
						Water_Stream{start = {x, last_empty_y}, direction = .East},
					)
				}
			case .Empty:
				last_empty_y = y
				if update_tilemap {tilemap[global_index(x, y)] = .Water}
			}
			y += 1
			iterations += 1
		}
	case .West:
		last_empty_x: u16
		for x > 0 && !stream.finished && iterations < 50 {
			tile := tilemap[global_index(x, y)]
			#partial switch tile {
			// case .Water:
			// 	stream.finished = true
			// 	stream.reason = .Water
			// 	stream.end = Tile_Position{last_empty_x, y}
			case .Wall:
				stream.finished = true
				stream.reason = .Wall
				stream.end = Tile_Position{last_empty_x, y}
			case .Empty, .Water:
				last_empty_x = x
				if update_tilemap {tilemap[global_index(x, y)] = .Water}
				if tilemap[global_index(x, y + 1)] == .Empty {
					stream.finished = true
					stream.reason = .Drop
					stream.end = Tile_Position{x, y}
					append(&out_streams, Water_Stream{start = {x, y}, direction = .South})
				}
			}
			x -= 1
			iterations += 1
		}
	case .East:
		last_empty_x: u16
		for x < CELL_COUNT * TILE_COUNT && !stream.finished && iterations < 50 {
			tile := tilemap[global_index(x, y)]
			#partial switch tile {
			// case .Water:
			// 	stream.finished = true
			// 	stream.reason = .Water
			// 	stream.end = Tile_Position{last_empty_x, y}
			case .Wall:
				stream.finished = true
				stream.reason = .Wall
				stream.end = Tile_Position{last_empty_x, y}
			case .Empty, .Water:
				last_empty_x = x
				if update_tilemap {tilemap[global_index(x, y)] = .Water}
				if tilemap[global_index(x, y + 1)] == .Empty {
					stream.finished = true
					stream.reason = .Drop
					stream.end = Tile_Position{x, y}
					append(&out_streams, Water_Stream{start = {x, y}, direction = .South})
				}
			}
			x += 1
			iterations += 1
		}
	}
	return out_streams
}

unfinished_streams :: proc(streams: []Water_Stream) -> int {
	count: int
	for s in streams {
		if !s.finished {
			count += 1
		}
	}
	return count
}

Water_Stream :: struct {
	start:     Tile_Position,
	end:       Tile_Position,
	direction: Direction,
	finished:  bool,
	reason:    enum {
		Wall,
		Water,
		Drop,
		WallDrop,
	},
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
		if !s.finished do count += 1
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

range_from_stream :: proc(s: Water_Stream) -> Tile_Range {
	return Tile_Range {
		min = math.min(s.start.x, s.end.x),
		max = math.max(s.start.x, s.end.x),
		y = s.start.y,
	}
}

range_overlap :: proc(a, b: Tile_Range) -> bool {
	return a.min <= b.max && b.min <= a.max && a.y == b.y
}

bake_entities :: proc() {
	// Bake entities from the bottom up to calculate starting position based on physics rules
	for y := (TILE_COUNT * CELL_COUNT) - 1; y > 0; y -= 1 {
		for x in 0 ..< TILE_COUNT * CELL_COUNT {
			entity := initial_entity_map[global_index(x, y)]
			switch entity {
			case .None:
				continue
			case .Box:
				resolve_box({u16(x), u16(y)})
			}
		}
	}
}

resolve_box :: proc(starting_pos: Tile_Position) {
	x, y := int(starting_pos.x), int(starting_pos.y)

	last_empty_y := y
	for y < TILE_COUNT * CELL_COUNT {
		tile := tilemap[global_index(x, y)]
		entity := initial_entity_map[global_index(x, y)]
		if tile == .Wall || entity == .Box {
			initial_entity_map[global_index(starting_pos.x, starting_pos.y)] = .None
			initial_entity_map[global_index(x, last_empty_y)] = .Box
			break
		} else {
			last_empty_y = y
		}
		y += 1
	}
}
