package main

import "core:fmt"


main :: proc() {
	init()
	for should_run() {
		update()
	}
	shutdown()
}
