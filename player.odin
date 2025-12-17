/*
	 Logic pertaining to player input and player character behaviour
*/
package main

import "core:log"
import "core:math"
import rl "vendor:raylib"

// How far can the player jump horizontally (in pixels)
MAX_JUMP_DISTANCE: f32 : 3
// How long to reach jump peak (in seconds)
TIME_TO_PEAK: f32 : 0.35
// How long to reach height we jumped from (in seconds)
TIME_TO_DESCENT: f32 : 0.2
// How many pixels high can we jump
JUMP_HEIGHT: f32 : 2

max_speed := calculate_max_speed()
jump_speed := calulate_jump_speed()
rising_gravity := calculate_rising_gravity()
falling_gravity := calculate_falling_gravity()

calulate_jump_speed :: proc "c" () -> f32 {
	return (-2 * JUMP_HEIGHT) / TIME_TO_PEAK
}

calculate_rising_gravity :: proc "c" () -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_PEAK, 2)
}

calculate_falling_gravity :: proc "c" () -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_DESCENT, 2)
}

calculate_max_speed :: proc "c" () -> f32 {
	return MAX_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}

Player :: struct {
	state:        Player_State,
	move_delta:   f32,
	translation:  Vec2,
	velocity:     Vec2,
	snapshot:     Vec2,
	radius:       f32,
	acceleration: f32,
	deceleration: f32,
	facing:       f32,
	held_entity:  Maybe(Entity_Id),
}

Player_State :: enum {
	Grounded,
	Airborne,
}

apply_player_velocity :: proc() {
	player := &world.player
	player.translation += player.velocity * TICK_RATE
	set_light_position(&world.lighting.lights[0], extend(player.translation, 0))
}

apply_player_gravity :: proc() {
	player := &world.player
	if player.velocity.y < 0 {
		player.velocity.y += rising_gravity * TICK_RATE
	} else {
		player.velocity.y += falling_gravity * TICK_RATE
	}
}

player_jump :: proc() {
	player := &world.player
	if is_action_buffered(.Jump) {
		switch player.state {
		case .Grounded:
			player.velocity.y = jump_speed
			consume_action(.Jump)
		case .Airborne:
		}
	}
}

player_movement :: proc() {
	player := &world.player
	if player.move_delta != 0 {
		if player.move_delta * player.velocity.x < max_speed {
			player.velocity.x += TICK_RATE * player.acceleration * player.move_delta
		}
	} else {
		factor := 1 - player.deceleration
		player.velocity.x = player.velocity.x * factor
		if math.abs(player.velocity.x) < 1 {
			player.velocity.x = 0
		}
	}
}

player_grab :: proc() {
	player := &world.player
	// Check if any entities collide with the grab box when the button is pressed
	// if we find one, turn it's rigidbody kinematic, remove collision and have the player carry it
	for entity in entities {
		// Collision
		//	If collision is made and button is pressed
		//		Set held entity to point to the grabbed entity
	}
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
	player_pos := extend(player.snapshot, 0)
	rl.BeginShaderMode(assets.lighting_shader)
	rl.DrawSphere(player_pos, player.radius, rl.RED)
	rl.EndShaderMode()
	// Grab box
	// rl.DrawCubeV(player_pos + {0.75 * player.facing, 0, 0}, {1.5, 1, 1}, {120, 0, 0, 100})
}
