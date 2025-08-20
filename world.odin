package main

import rl "vendor:raylib"

World :: struct {
	world_map: World_Map
}

make_world :: proc() -> ^World {
	world_ptr := new(World)
	return world_ptr
}

delete_world :: proc() {
	free(world)
}
