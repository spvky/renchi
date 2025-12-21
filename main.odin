/*
	 True application entrypoint
*/
package main

import "base:runtime"
import "core:log"

main :: proc() {
	// Customize the logger
	context.logger = log.create_console_logger(
		opt = runtime.Logger_Options{.Level, .Short_File_Path, .Line},
	)
	log.debugf("Tile: %v | Lighting: %v", size_of(Tile), size_of(Lighting))
	log.debugf("Old World: %v | New World: %v", size_of(World), size_of(New_World))
	log.debugf("Old Entity: %v | New Entity: %v", size_of(Entity), size_of(New_Entity))
	log.debugf("Old Rigidbody: %v | New Rigidbody: %v", size_of(Rigidbody), size_of(New_Rigidbody))
	init()
	for should_run() {
		update()
	}
	shutdown()
}
