/*
	 Logic pertaining to player input
*/
package main

import rl "vendor:raylib"

input_buffer: Input_Buffer

Input_Buffer :: struct {
	actions: [Input_Action]Buffered_Input,
}

Buffered_Input :: union {
	f32,
}

Input_Action :: enum {
	Jump,
	Dash,
}

update_buffer :: proc() {
	frametime := rl.GetFrameTime()

	for &buffered in input_buffer.actions {
		switch &v in buffered {
		case f32:
			v -= frametime
			if v <= 0 {
				buffered = nil
			}
		}
	}
}

buffer_action :: proc(action: Input_Action) {
	switch &v in input_buffer.actions[action] {
	case f32:
		v = 0.15
	case:
		input_buffer.actions[action] = 0.15
	}
}

consume_action :: proc(action: Input_Action) {
	input_buffer.actions[action] = nil
}

is_action_buffered :: proc(action: Input_Action) -> bool {
	_, action_pressed := input_buffer.actions[action].(f32)
	return action_pressed
}

poll_input :: proc() {
	delta: f32
	facing := world.player.facing
	if rl.IsKeyDown(.A) {
		delta -= 1
		facing = -1
	}
	if rl.IsKeyDown(.D) {
		delta += 1
		facing = 1
	}

	world.player.move_delta = delta
	world.player.facing = facing
	update_buffer()
	if rl.IsKeyPressed(.SPACE) do buffer_action(.Jump)
}
