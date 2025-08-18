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

Cell :: struct {
	tiles: [16][16]Tile,
}

Cell_Position :: [2]i16

Tile_Position :: [2]i16

Tile :: enum u8 {
	Empty,
	Wall,
	OneWay,
	Door,
}


rotate_cell :: proc(tiles: ^[16][16]Tile) {
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
}
