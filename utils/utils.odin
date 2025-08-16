package utils

import "core:c"
import rl "vendor:raylib"

// Wraps os.read_entire_file and os.write_entire_file, but they also work with emscripten.
@(require_results)
read_entire_file :: proc(
	name: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	data: []byte,
	success: bool,
) {
	return _read_entire_file(name, allocator, loc)
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return _write_entire_file(name, data, truncate)
}

// A way to load textures that works on desktop and web, only works for png files
load_texture :: proc(filepath: string) -> rl.Texture {
	texture: rl.Texture
	if texture_data, texture_ok := read_entire_file(filepath, context.temp_allocator); texture_ok {
		texture_img := rl.LoadImageFromMemory(
			".png",
			raw_data(texture_data),
			c.int(len(texture_data)),
		)
		texture = rl.LoadTextureFromImage(texture_img)
		rl.UnloadImage(texture_img)
	}
	return texture
}
