package main

import "core:math"
import rl "vendor:raylib"


////////////// Physics values ///////////////////

// How far can the player jump horizontally (in pixels)
MAX_JUMP_DISTANCE: f32 : TILE_SIZE * 3
// How long to reach jump peak (in seconds)
TIME_TO_PEAK: f32 : 0.35
// How long to reach height we jumped from (in seconds)
TIME_TO_DESCENT: f32 : 0.2
// How many pixels high can we jump
JUMP_HEIGHT: f32 : TILE_SIZE * 2

max_speed := calculate_max_speed()
jump_speed := calulate_jump_speed()
rising_gravity := calculate_rising_gravity()
falling_gravity := calculate_falling_gravity()


calulate_jump_speed :: proc() -> f32 {
	return (-2 * JUMP_HEIGHT) / TIME_TO_PEAK
}

calculate_rising_gravity :: proc() -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_PEAK, 2)
}

calculate_falling_gravity :: proc() -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_DESCENT, 2)
}

calculate_max_speed :: proc() -> f32 {
	return MAX_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}

//////////////////////////////////////////////

Player :: struct {
	using rigidbody: ^Rigidbody,
	state:           Player_State,
}

Player_State :: enum {
	Grounded,
	Airborne,
}

draw_player :: proc() {
	player := world.player
	color: rl.Color
	switch player.state {
	case .Grounded:
		color = rl.WHITE
	case .Airborne:
		color = rl.BLUE
	}
	rl.DrawCircleV(player.snapshot, 8, color)
}
