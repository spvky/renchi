package main

import "core:fmt"

bake_map :: proc() {
	place_tiles()
}

place_tiles :: proc() {
	tiles_added: int
	for room, tag in rooms {
		if room.placed {
			for position, cell in room.cells {
				tiles := rotate_cell(cell.tiles, room.rotation)
				// add rooms tiles to the tilemap
				for x in 0 ..< 16 {
					for y in 0 ..< 16 {
						tile := tiles[tile_index(x, y)]
						if tile != .Empty {
							tiles_added += 1
							tilemap[tile_global_index(x, y, room.position - position)] = tile
						}
					}
				}
			}
		}
	}
	fmt.printfln("%v Tiles Placed", tiles_added)
}
