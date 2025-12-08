package main

import "core:log"


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

Water_Volume :: struct {
	top:    int,
	bottom: int,
	left:   int,
	right:  int,
}

water_volume_contains :: proc(wv: Water_Volume, pos: Vec2) -> bool {
	contains_point :=
		(pos.x >= f32(wv.left) &&
			pos.x <= f32(wv.right) &&
			pos.y >= f32(wv.top) + 0.5 &&
			pos.y <= f32(wv.bottom + 1))
	return contains_point
}
