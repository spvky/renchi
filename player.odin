package main

import "core:log"
import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

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

Player :: struct {
	state:        Player_State,
	move_delta:   f32,
	translation:  Vec2,
	velocity:     Vec2,
	snapshot:     Vec2,
	radius:       f32,
	acceleration: f32,
	deceleration: f32,
}

Player_State :: enum {
	Grounded,
	Airborne,
}

apply_player_velocity :: proc() {
	player := &world.player
	player.translation += player.velocity * TICK_RATE
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

player_platform_collision :: proc() {
	player := &world.player
	player_feet := player.translation + Vec2{0, 8}
	foot_collision: bool
	collisions := make([dynamic]Collision_Data, 0, 8, allocator = context.temp_allocator)
	for collider in colliders {
		nearest_point := collider_nearest_point(collider, player.translation)
		if l.distance(nearest_point, player.translation) < player.radius {
			collision := calculate_collision(player, nearest_point)
			append(&collisions, collision)
		}
		if l.distance(nearest_point, player_feet) < 1.5 {
			foot_collision = true
		}
		for collision in collisions {
			player.translation += collision.mtv
			x_dot := math.abs(l.dot(collision.normal, Vec2{1, 0}))
			y_dot := math.abs(l.dot(collision.normal, Vec2{0, 1}))
			if x_dot > 0.7 {
				player.velocity.x = 0
			}
			if y_dot > 0.7 {
				player.velocity.y = 0
			}
		}
	}
	if foot_collision {
		player.state = .Grounded
	} else {
		player.state = .Airborne
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
	rl.DrawCircleV(player.snapshot, 8, color)
}
