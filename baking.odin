/*
	 Logic pertaining to translating the created map into actual rooms in the game world
*/
package main

import "core:log"
import "core:math"
import "core:slice"
import "core:time"
import rl "vendor:raylib"

Wall_Chain :: struct {
	y_start: int,
	y_end:   int,
	start:   int,
	end:     int,
}

Water_Path :: struct {
	segments: [dynamic]Water_Path_Segment,
}

Water_Path_Segment :: struct {
	start:     Tile_Position,
	end:       Tile_Position,
	length:    int,
	direction: Direction,
	level:     int,
	finished:  bool,
}

bake_map :: proc(t: ^Tilemap) {
	place_tiles(t)
	log.debug("Finished placing tiles")
	generate_collision(t^)
	log.debug("Finished generating collision")
	bake_water(t)
	log.debug("Finished baking water")
}

reset_map :: proc(tilemap: ^Tilemap) {

	clear(&tilemap.collision_tiles)
	clear(&tilemap.entity_tiles)
	for &room, _ in rooms {
		room.placed = false
	}
}

draw_tilemap :: proc(t: Tilemap) {
	draw_colliders()
	draw_water_paths(t)
}

draw_water_paths :: proc(t: Tilemap) {
	for p in t.water_paths {
		for s in p.segments {
			start := Vec3{f32(s.start.x), f32(s.start.y), 0}
			end: Vec3
			#partial switch s.direction {
			case .East:
				end = start + Vec3{f32(s.length), 0, 0}
			case .West:
				end = start - Vec3{f32(s.length), 0, 0}
			case .South:
				end = start + Vec3{0, f32(s.length), 0}
			}
			rl.DrawLine3D(start, end, rl.BLUE)
		}
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

	half := Vec2{0.5, 0.5}
	for chain in wall_chains {
		min := Vec2{f32(chain.start), f32(chain.y_start)} - half
		max := Vec2{f32(chain.end + 1), f32(chain.y_end + 1)} - half
		collider := Collider {
			min = min,
			max = max,
		}
		append(&colliders, collider)
	}

	end_time := time.now()
	total_duration := time.duration_milliseconds(time.diff(start_time, end_time))

	if ODIN_DEBUG {
		log.debugf("Collision Generation took %v ms", total_duration)
	}
}

// For now to keep things seperated this will be a totally seperate baking step, ideally we would iterate the tilemap as few times as possible
bake_water :: proc(t: ^Tilemap) {
	map_width, map_height := get_tilemap_dimensions(t^, false)
	for y in 0 ..< map_height {
		for x in 0 ..< map_width {
			tile := get_static_tile(t^, x, y)
			if tile == .Water {
				path := resolve_water_path(t^, {u16(x), u16(y)}, .South)
				append(&t.water_paths, path)
			}
		}
	}
	if ODIN_DEBUG {
		log.debugf("Paths: %v", t.water_paths)
	}
}


resolve_water_path :: proc(t: Tilemap, start: Tile_Position, direction: Direction) -> Water_Path {
	segments := make([dynamic]Water_Path_Segment, 0, 8)
	append(&segments, Water_Path_Segment{start = start, direction = direction, level = 0})

	solving := true
	// Outer loop that is manually broken because we will be adding to a collection while iterating it
	for solving { 	// Loop 1
		for &s, i in segments { 	// Loop 2
			pos: [2]int = {int(s.start.x), int(s.start.y)}
			shift := shift_from_direction(s.direction)
			for !s.finished {
				pos += shift
				current_tile := get_static_tile(t, pos.x, pos.y)
				if water_passthrough(current_tile) { 	// If water can pass through the current tile
					s.length += 1
					if is_horizontal(s.direction) { 	// Is the stream travelling East/West
						tile_below := get_static_tile(t, pos.x, pos.y + 1)
						if water_passthrough(tile_below) { 	// Did the stream enter empty space with another passable tile beneath it ?
							s.finished = true
							s.end = s.start + {u16(s.length * shift.x), u16(s.length * shift.y)}
							append(
								&segments,
								Water_Path_Segment {
									start = {u16(pos.x), u16(pos.y + 1)},
									direction = .South,
									level = s.level + 1,
								},
							)
						}
					}
				} else { 	// If water cannot pass through the current tile
					s.finished = true
					s.end = s.start + {u16(s.length * shift.x), u16(s.length * shift.y)}
					if !is_horizontal(s.direction) {
						left_pos := [2]int{pos.x - 1, pos.y - 1}
						right_pos := [2]int{pos.x + 1, pos.y - 1}
						left_tile := get_static_tile(t, left_pos.x, left_pos.y)
						right_tile := get_static_tile(t, right_pos.x, right_pos.y)
						if water_passthrough(left_tile) {
							append(
								&segments,
								Water_Path_Segment {
									start = {u16(left_pos.x), u16(left_pos.y)},
									direction = .West,
									level = s.level + 1,
								},
							)
						}
						if water_passthrough(right_tile) {
							append(
								&segments,
								Water_Path_Segment {
									start = {u16(right_pos.x), u16(right_pos.y)},
									direction = .East,
									level = s.level + 1,
								},
							)
						}
					}
				}
			}
		}
		unfinished := unfinished_segments(segments[:])
		solving = unfinished > 0
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

unfinished_segments :: proc(segments: []Water_Path_Segment) -> int {
	count: int
	for s in segments {
		if !s.finished {
			count += 1
		}
	}
	return count
}
