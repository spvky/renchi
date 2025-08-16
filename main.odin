package main


main :: proc() {
	init()
	for should_run() {
		update()
	}
	shutdown()
}
