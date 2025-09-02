package main

import "core:math"
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

Collision_Data :: struct {
	normal: Vec2,
	mtv:    Vec2,
}

physics_step :: proc() {
	player_platform_collision()
	player_movement()
	apply_player_gravity()
	apply_player_velocity()
}


collider_nearest_point :: proc(c: Collider, v: Vec2) -> Vec2 {
	return l.clamp(v, c.min, c.max)
}


calculate_collision :: proc(player: ^Player, nearest_point: Vec2) -> Collision_Data {
	collision: Collision_Data
	collision_vector := player.translation - nearest_point
	pen_depth := player.radius - l.length(collision_vector)
	collision_normal := l.normalize(collision_vector)
	mtv := collision_normal * pen_depth
	collision.normal = collision_normal
	collision.mtv = mtv
	return collision
}
