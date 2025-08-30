package main

import l "core:math/linalg"


Collider :: struct {
	max: Vec2,
	min: Vec2,
}

collider_nearest_point :: proc(c: Collider, v: Vec2) -> Vec2 {
	return l.clamp(v, c.min, c.max)
}
