package main

import rl "vendor:raylib"

World :: struct {
	camera: rl.Camera2D,
	player: Player,
}

make_world :: proc() -> World {
	player_rigidbody := Rigidbody {
		shape = Circle{radius = 8},
	}
	player := Player {
		rigidbody = &player_rigidbody,
	}
	append(&rigidbodies, player_rigidbody)
	return World{camera = rl.Camera2D{zoom = 1}, player = player}
}
