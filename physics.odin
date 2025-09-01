package main

import l "core:math/linalg"

Rigidbody :: struct {
	translation: Vec2,
	velocity:    Vec2,
	snapshot:    Vec2,
	shape:       Collision_Shape,
}

Collision_Shape :: union {
	Circle,
	Rectangle,
}

Circle :: struct {
	radius: f32,
}

Rectangle :: struct {
	extents: Vec2,
}

Collider :: struct {
	max: Vec2,
	min: Vec2,
}

collider_nearest_point :: proc(c: Collider, v: Vec2) -> Vec2 {
	return l.clamp(v, c.min, c.max)
}
