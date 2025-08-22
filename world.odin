package main

import rl "vendor:raylib"

World :: struct {
	world_map: World_Map,
}

make_world :: proc() -> World {
	return World{}
}
