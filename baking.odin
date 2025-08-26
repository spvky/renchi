package main

import "core:log"
import "core:math"
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
	for y in 0 ..< 256 {
		for x in 0 ..< 256 {
			tile := tilemap[global_index(x, y)]
			if tile == .Wall {
				rl.DrawCircleV({f32(x) * 2, f32(y) * 2}, 1, rl.BLACK)
			}
		}
	}
}

place_tiles :: proc() {
	tiles_added: int
	for room, tag in rooms {
		if room.placed {
			for position, cell in room.cells {
				tiles := rotate_cell(cell.tiles, room.rotation)
				// add rooms tiles to the tilemap
				for y in 0 ..< 16 {
					for x in 0 ..< 16 {
						cell_pos := cell_global_position(position, room.position, room.rotation)

						raw_x := x + int(cell_pos.x * 16)
						raw_y := y + int(cell_pos.y * 16)
						tile := tiles[tile_index(x, y)]
						if tile != .Empty {
							// fmt.printfln(
							// 	"Placing tile:\n\tCell Pos: %v\n\tx,y : %v, %v\n\traw x,y : %v, %v",
							// 	cell_pos,
							// 	x,
							// 	y,
							// 	raw_x,
							// 	raw_y,
							// )
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
	y_value: int,
	start:   int,
	end:     int,
}

generate_collision :: proc() {
	// colliders := make([dynamic]Collider, 0, 128)
	wall_chains := make([dynamic]Wall_Chain, 0, 32, allocator = context.temp_allocator)
	x, y: int
	for y < 256 {
		x = 0
		for x < 256 {
			tile := tilemap[global_index(x, y)]
			if tile == .Wall {
				log.debugf("Found a wall at %v, %v starting a chain\n", x, y)
				chain := Wall_Chain {
					start   = x,
					end     = x,
					y_value = y,
				}
				x += 1
				for tilemap[global_index(x, y)] == .Wall && x < 256 {
					chain.end = x
					x += 1
				}
				append(&wall_chains, chain)
			}
			x += 1
		}
		y += 1
	}
	log.debugf("Generated %v wall chains", len(wall_chains))
	log.debugf("Chains: %v", wall_chains)
}
