/*
	 Logic pertaining to the user interface
*/
package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

ui_texture_atlas: [Ui_Texture_Tag]rl.Texture

Ui_Texture_Tag :: enum {
	Cursor,
}

load_ui_textures :: proc() -> [Ui_Texture_Tag]rl.Texture {
	return {.Cursor = rl.LoadTexture("assets/textures/map_screen_cursor.png")}
}

unload_ui_textures :: proc() {
	for texture, _ in ui_texture_atlas {
		rl.UnloadTexture(texture)
	}
}

// Making some helper functions for editor ui

top_row_buttons: [dynamic]Button

EDITOR_FONT_SIZE :: 36
BUTTON_MARGIN :: 5
button_position: [2]i32

Button :: struct {
	text:     string,
	callback: Button_Callback,
}

Button_Callback :: proc()

init_ui :: proc() {
	top_row_buttons = make([dynamic]Button, 0, 4)
	append(&top_row_buttons, Button {
		text = "Save",
		callback = proc() {fmt.println("Game Saved")},
	})
	append(&top_row_buttons, Button {
		text = "Quit",
		callback = proc() {fmt.println("Quitting Game")},
	})
	append(&top_row_buttons, Button {
		text = "Play",
		callback = proc() {fmt.println("Starting Game")},
	})
}

draw_buttons :: proc() {
	button_position = {0, 0}
	for b in top_row_buttons {
		button(b.text, b.callback)
	}
}

button :: proc(raw_text: string, callback: Button_Callback) {
	text := strings.clone_to_cstring(raw_text, allocator = context.temp_allocator)
	width := rl.MeasureText(text, EDITOR_FONT_SIZE)
	pressed, down := is_button_clicked(width)
	color: rl.Color = down ? {50, 50, 50, 255} : {100, 100, 100, 255}
	rl.DrawRectangle(button_position.x, button_position.y, width + 8, EDITOR_FONT_SIZE, color)
	rl.DrawText(text, button_position.x + 4, button_position.y, EDITOR_FONT_SIZE, rl.WHITE)
	button_position.x += width + (BUTTON_MARGIN * 2)
	if pressed {
		callback()
	}
}

is_button_clicked :: proc(width: i32) -> (pressed: bool, down: bool) {
	mouse_pressed := rl.IsMouseButtonPressed(.LEFT)
	mouse_down := rl.IsMouseButtonDown(.LEFT)
	cursor_min: [2]i32 = {button_position.x, button_position.y}
	cursor_max: [2]i32 = {button_position.x + width + 8, button_position.y + width}
	raw_cursor_pos := rl.GetMousePosition()
	cursor_pos: [2]i32 = {i32(raw_cursor_pos.x), i32(raw_cursor_pos.y)}

	in_range :=
		cursor_pos.x >= cursor_min.x &&
		cursor_pos.x <= cursor_max.x &&
		cursor_pos.y >= cursor_min.y &&
		cursor_pos.y <= cursor_max.y

	pressed = mouse_pressed && in_range
	down = mouse_down && in_range
	return
}
