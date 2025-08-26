package main

import l "core:math/linalg"


Collider :: struct {
	position: Vec2,
	extents:  Vec2,
}

collider_nearest_point :: proc(c: Collider, v: Vec2) -> Vec2 {
	min := c.position - (c.extents / 2)
	max := c.position + (c.extents / 2)
	return l.clamp(v, min, max)
}
