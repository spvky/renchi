/*
	 Utility procs that are used all over
*/
package main

import intr "base:intrinsics"
import "core:strings"
import "utils"
import rl "vendor:raylib"

Vec2 :: [2]f32
Vec3 :: [3]f32
V_ONE :: Vec3{1, 1, 1}
Cell_Position :: [2]i16
Tile_Position :: [2]u16

// Is the passed direction horizontal
is_horizontal :: proc(d: Direction) -> bool {
	return d in bit_set[Direction]{.East, .West}
}

// Can water pass through the given tile
water_passthrough :: proc(t: Tile) -> bool {
	return t in bit_set[Tile]{.Empty}
}

extend :: proc(v: Vec2, z: f32) -> Vec3 {
	return Vec3{v.x, v.y, z}
}

load_texture :: proc(filename: string) -> rl.Texture {
	when ODIN_OS == .JS {
		return utils.load_texture(filename)
	}
	return rl.LoadTexture(strings.clone_to_cstring(filename))
}

tile_index :: proc(x, y: $T) -> int where intr.type_is_integer(T) {
	return int(x + (y * CD))
}

cell_global_position :: proc(
	cell_pos, room_pos: Cell_Position,
	room_rot: Direction,
) -> Cell_Position {
	rotated_pos := cell_pos
	rotations: int
	#partial switch room_rot {
	case .East:
		rotations = 1
	case .South:
		rotations = 2
	case .West:
		rotations = 3
	}

	for _ in 0 ..< rotations {
		rotated_pos = {-rotated_pos.y, rotated_pos.x}
	}
	final_pos := rotated_pos + room_pos
	return final_pos
}

vec_from_map_cell_position :: proc(t: Tilemap, position: Cell_Position) -> Vec2 {
	grid_offset := get_tilemap_grid_offset(t)
	return Vec2{12.5, 12.5} + Vec2{f32(position.x) * CD, f32(position.y) * CD} + grid_offset
}

float_rotation_from_room_rotation :: proc(rotation: Direction) -> f32 {
	float_rotation: f32
	#partial switch rotation {
	case .East:
		float_rotation = 90
	case .South:
		float_rotation = 180
	case .West:
		float_rotation = 270
	}

	return float_rotation
}
