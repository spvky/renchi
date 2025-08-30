package main

import rl "vendor:raylib"

World :: struct {
	camera:    rl.Camera2D,
	world_map: World_Map,
}

make_world :: proc() -> World {
	return World{camera = rl.Camera2D{zoom = 1}}
}
