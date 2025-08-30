package main

import l "core:math/linalg"
import rl "vendor:raylib"

move_camera :: proc() {
	if game_state == .Gameplay {
		move_delta: Vec2

		if rl.IsKeyDown(.A) {
			move_delta.x -= 1
		}
		if rl.IsKeyDown(.D) {
			move_delta.x += 1
		}
		if rl.IsKeyDown(.W) {
			move_delta.y -= 1
		}
		if rl.IsKeyDown(.S) {
			move_delta.y += 1
		}

		if move_delta != {0, 0} {
			normalized := l.normalize(move_delta)
			frametime := rl.GetFrameTime()
			world.camera.target += frametime * (normalized * 64)
		}
	}
}
