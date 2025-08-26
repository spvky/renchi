package main

import "base:runtime"
import "core:log"

main :: proc() {
	context.logger = log.create_console_logger(
		opt = runtime.Logger_Options{.Level, .Short_File_Path, .Line},
	)
	init()
	for should_run() {
		update()
	}
	shutdown()
}
