package main

Room :: struct {
	cells:      map[Cell_Position]Cell,
	width:      u8,
	height:     u8,
	cell_count: u8,
}

Room_Rotation :: enum u8 {
	North,
	East,
	West,
	South,
}

Map_Room :: struct {
	rotation: Room_Rotation,
	ptr:      ^Room,
}


Room_Tag :: enum {
	A,
	B,
	C,
	D,
}

room_pivot_from_tag :: proc(tag: Room_Tag) -> Cell_Position {
	position: Cell_Position
	#partial switch tag {
	case .A:
		position = {1, 0}
	case .D:
		position = {2, 1}
	}
	return position
}

// Permanent representation of a room cell
Cell :: struct {
	tiles: [16][16]Tile,
}

// Representation of a cell when it's in the world map
Map_Cell :: struct {
	rotation: Room_Rotation,
	tiles:    [16][16]Tile,
}

Cell_Position :: [2]i16

Tile_Position :: [2]i16

Tile :: enum u8 {
	Empty,
	Wall,
	OneWay,
	Door,
}


rotate_cell :: proc(in_tiles: [16][16]Tile, rotation: Room_Rotation) -> [16][16]Tile {
	if rotation == .North {
		return in_tiles
	}
	rotations: int
	#partial switch rotation {
	case .East:
		rotations = 1
	case .South:
		rotations = 2
	case .West:
		rotations = 3
	}
	tiles := in_tiles
	for rotations > 0 {
		for i in 0 ..< 16 {
			for j in i + 1 ..< 16 {
				tiles[i][j], tiles[j][i] = tiles[j][i], tiles[i][j]
			}
		}
		for i in 0 ..< 16 {
			start, end := 0, 15
			for start < end {
				tiles[i][start], tiles[i][end] = tiles[i][end], tiles[i][start]
				start += 1
				end -= 1
			}
		}
		rotations -= 1
	}
	return tiles
}
