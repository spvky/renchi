/*
	 Logic pertaining to the user interface
*/
package main

import "core:fmt"
import "core:math"
import "core:strings"
import "core:text/i18n"
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
toasts: [dynamic]Toast

EDITOR_FONT_SIZE :: 36
BUTTON_MARGIN :: 5
TOAST_LIFETIME: f32 : 5
button_position: [2]i32

Button :: struct {
	text:     string,
	callback: Button_Callback,
}

Button_Callback :: proc()

init_ui :: proc() {
	top_row_buttons = make([dynamic]Button, 0, 4)
	append(
		&top_row_buttons,
		Button {
			text = "Save",
			callback = proc() {
				// fmt.println("Game Saved")
				append(&toasts, Toast{lifetime = 0})
			},
		},
	)
	append(&top_row_buttons, Button {
		text = "Quit",
		callback = proc() {fmt.println("Quitting Game")},
	})
	append(&top_row_buttons, Button {
		text = "Play",
		callback = proc() {fmt.println("Starting Game")},
	})
	toasts = make([dynamic]Toast)
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

Toast :: struct {
	lifetime: f32,
}

draw_toasts :: proc() {
	indexes_to_remove := make([dynamic]int)
	for &toast, i in toasts {
		if handle_toast(&toast) {
			append(&indexes_to_remove, i)
		}
	}

	for i in indexes_to_remove {
		unordered_remove(&toasts, i)
	}
	delete(indexes_to_remove)
}

handle_toast :: proc(toast: ^Toast) -> bool {
	toast.lifetime = math.clamp(toast.lifetime + rl.GetFrameTime(), 0, TOAST_LIFETIME)
	c4: f32 = (2 * math.PI) / 3
	v := toast.lifetime / TOAST_LIFETIME
	// Ease out elastic, from easings.net
	t: f32
	if v == 0 {
		t = 0
	} else if v == 1 {
		t = 1
	} else {
		t = math.pow_f32(2, -10 * v) * math.sin_f32((v * -10 - 0.75) * c4) + 1
	}
	///

	// Determine toast position
	start := f32(WINDOW_HEIGHT)
	end: f32
	lerp := math.lerp(start, end, t)
	x: i32 = 1500
	y := i32(lerp)

	rl.DrawRectangle(x, y, 90, 40, rl.GREEN)


	return v == 1
}
