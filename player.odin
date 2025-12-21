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
clinging_gravity := falling_gravity * 0.05

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
	move_delta:            f32,
	translation:           Vec2,
	velocity:              Vec2,
	snapshot:              Vec2,
	radius:                f32,
	acceleration:          f32,
	deceleration:          f32,
	facing:                f32,
	lateral_movement_lock: u16,
	state_flags:           bit_set[Player_State_Flags;u8],
	prev_state_flags:      bit_set[Player_State_Flags;u8],
}

// Data that holds additional player data
Player_Data :: struct {
	move_delta:            f32,
	acceleration:          f32,
	deceleration:          f32,
	facing:                f32,
	lateral_movement_lock: u16,
	state_flags:           bit_set[Player_State_Flags;u8],
	prev_state_flags:      bit_set[Player_State_Flags;u8],
}

Player_State_Flags :: enum u8 {
	Grounded,
	Jumping,
	TouchingLeftWall,
	TouchingRightWall,
	DoubleJump,
	Clinging,
}

apply_player_velocity :: proc() {
	player := &world.player
	player.translation += player.velocity * TICK_RATE
	set_light_position(&world.lighting.lights[0], extend(player.translation, 0))
}

apply_player_gravity :: proc() {
	player := &world.player
	if .Clinging in player.state_flags {
		player.velocity.y += clinging_gravity * TICK_RATE
	} else {
		if player.velocity.y < 0 {
			player.velocity.y += rising_gravity * TICK_RATE
		} else {
			player.velocity.y += falling_gravity * TICK_RATE
		}
	}
}
manage_player_state_flags :: proc() {
	player := &world.player
	if card(player.state_flags & {.TouchingLeftWall, .TouchingRightWall}) == 0 &&
	   card(player.prev_state_flags & {.TouchingLeftWall, .TouchingRightWall}) == 0 {
		player.state_flags -= {.Clinging}
	}
	gained := player.state_flags - player.prev_state_flags
	lost := player.prev_state_flags - player.state_flags
	if card(gained) > 0 || card(lost) > 0 {
		publish_event(
			.Player_State_Change,
			Event_Player_State_Change_Payload{lost = lost, gained = gained},
		)
	}
	prev := player.prev_state_flags
	player.prev_state_flags = player.state_flags
}

player_jump :: proc() {
	player := &world.player
	if is_action_buffered(.Jump) {
		if .Grounded in player.state_flags {
			player.velocity.y = jump_speed
			consume_action(.Jump)
			return
		}
		if .Clinging in player.state_flags {
			dir: f32
			if .TouchingLeftWall in player.state_flags {
				dir += 1
			}
			if .TouchingRightWall in player.state_flags {
				dir -= 1
			}
			player.velocity.y = jump_speed * 0.625
			player.move_delta = dir
			player.velocity.x = dir * max_speed * 1.5
			player.lateral_movement_lock = 25
			player.state_flags -= {.Clinging, .TouchingLeftWall, .TouchingRightWall}
			consume_action(.Jump)
			return
		}
		if .DoubleJump in player.state_flags {
			player.velocity.y = jump_speed * 0.85
			player.state_flags -= {.DoubleJump}
			consume_action(.Jump)
			return
		}
	}
}

player_movement :: proc() {
	player := &world.player
	if player.lateral_movement_lock > 0 {
		player.lateral_movement_lock = clamp(player.lateral_movement_lock - 1, 0, 255)
	}
	if player.lateral_movement_lock == 0 {
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

// Rendering

draw_player :: proc() {
	player := world.player

	color: rl.Color
	if .Grounded in player.state_flags {
		color = rl.WHITE
	} else {
		color = rl.BLUE
	}
	player_pos := extend(player.snapshot, 0)
	rl.DrawSphere(player_pos, player.radius, color)
	// Grab box
	// rl.DrawCubeV(player_pos + {0.75 * player.facing, 0, 0}, {1.5, 1, 1}, {120, 0, 0, 100})
}

register_player_event_listeners :: proc() {
	subscribe_event(.Player_State_Change, player_player_state_change_callback)
}

// Event Callbacks
player_player_state_change_callback :: proc(event: Event) {
	player := &world.player
	#partial switch event.type {
	case .Player_State_Change:
		payload := event.payload.(Event_Player_State_Change_Payload)
		gained, lost := payload.gained, payload.lost
		// Initiate Wall Cling
		if .Clinging in gained {
			player.velocity.y = 0
		}
	}
}
