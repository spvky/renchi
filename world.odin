package main

import rl "vendor:raylib"

World :: struct {
	camera: rl.Camera2D,
}

make_world :: proc() -> World {
	return World{camera = rl.Camera2D{zoom = 1}}
}
