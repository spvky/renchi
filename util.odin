package main

import "core:strings"
import rl "vendor:raylib"
import "utils"

Vec3 :: [3]f32

load_texture :: proc(filename: string) -> rl.Texture {
	when ODIN_OS == .JS {
		return utils.load_texture(filename)
	}
	return rl.LoadTexture(strings.clone_to_cstring(filename))
}
