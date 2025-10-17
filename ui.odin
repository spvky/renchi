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

// Row of buttons, contains a dynamic array of buttons
top_row_buttons: Button_Container
toasts: [dynamic]Toast

Button :: struct {
	text:     string,
	callback: proc(),
}

Button_Container :: struct {
	position: [2]i32,
	buttons:  [dynamic]Button,
	style:    Button_Style,
}

Button_Style :: struct {
	mode:      Button_Layout_Mode,
	font_size: i32,
	padding:   i32,
	margin:    i32,
}

DEFAULT_BUTTON_STYLE :: Button_Style {
	mode      = .Column,
	font_size = 36,
	padding   = 4,
	margin    = 5,
}

Button_Layout_Mode :: enum {
	Row,
	Column,
}


// Makes a button row, allocates with context.allocator
make_button_container :: proc(
	position: [2]i32,
	style: Button_Style = DEFAULT_BUTTON_STYLE,
	buttons: ..Button,
) -> Button_Container {
	initial_capacity := len(buttons)
	button_list := make([dynamic]Button, 0, initial_capacity)
	append_elems(&button_list, ..buttons)
	return Button_Container{position = position, buttons = button_list, style = style}
}

delete_button_row :: proc(row: Button_Container) {
	delete(row.buttons)
}

init_ui :: proc() {
	top_row_buttons = make_button_container({0, 0}, DEFAULT_BUTTON_STYLE, {
		text = "Save",
		callback = proc() {fmt.println("Game Saved")},
	}, {
		text = "Quit",
		callback = proc() {fmt.println("Quitting Game")},
	}, {
		text = "Play",
		callback = proc() {fmt.println("Starting Game")},
	})
}

draw_button_row :: proc(row: Button_Container) {
	position := row.position
	for b in row.buttons {
		handle_button(b, &position, row.style)
	}
}

// Draws the given button, and detects if it is clicked
handle_button :: proc(button: Button, position: ^[2]i32, style: Button_Style) {
	text := strings.clone_to_cstring(button.text, allocator = context.temp_allocator)
	width := rl.MeasureText(text, style.font_size)
	pressed, down := is_button_clicked(width, position, style)
	color: rl.Color = down ? {50, 50, 50, 255} : {100, 100, 100, 255}
	rl.DrawRectangle(position.x, position.y, width + (style.padding * 2), style.font_size, color)
	rl.DrawText(text, position.x + 4, position.y, style.font_size, rl.WHITE)
	if style.mode == .Row {
		position.x += width + (style.margin * 2)
	} else {
		position.y += style.font_size + style.margin
	}
	if pressed {
		button.callback()
	}
}

is_button_clicked :: proc(
	width: i32,
	position: ^[2]i32,
	style: Button_Style,
) -> (
	pressed: bool,
	down: bool,
) {
	mouse_pressed := rl.IsMouseButtonPressed(.LEFT)
	mouse_down := rl.IsMouseButtonDown(.LEFT)
	cursor_min: [2]i32 = {position.x, position.y}
	cursor_max: [2]i32 = {position.x + width + 8, position.y + style.font_size}
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

TOAST_LIFETIME: f32 : 5

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
	end: f32 = 200
	lerp := math.lerp(start, end, t)
	x: i32 = 1500
	y := i32(lerp)

	rl.DrawRectangle(x, y, 90, 40, rl.GREEN)


	return toast.lifetime >= TOAST_LIFETIME
}
