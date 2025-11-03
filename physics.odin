/*
*/
package main

import "core:log"
import "core:math"
import l "core:math/linalg"

colliders: [dynamic]Static_Collider
rigidbodies: [dynamic]Rigidbody

Rigidbody :: struct {
	collider: Physics_Collider,
	snapshot: Vec2,
	velocity: Vec2,
}

Staticbody :: struct {
	collider: Physics_Collider,
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

Static_Collider :: struct {
	max: Vec2,
	min: Vec2,
}

Collision_Data :: struct {
	normal: Vec2,
	mtv:    Vec2,
}


collider_vertices :: proc(c: Static_Collider) -> [4]Vec2 {
	return [4]Vec2{{c.min.x, c.max.y}, {c.min.x, c.min.y}, {c.max.x, c.max.y}, {c.max.x, c.min.y}}
}


init_physics_collections :: proc() {
	log.info("Rigidbodies Initialized")
	rigidbodies = make([dynamic]Rigidbody, 0, 16)
	log.info("Colliders Initialized")
	colliders = make([dynamic]Static_Collider, 0, 64)
}

clear_physics_collectsions :: proc() {
	clear(&rigidbodies)
	clear(&colliders)
}

delete_physics_collections :: proc() {
	delete(rigidbodies)
	delete(colliders)
}

physics_step :: proc() {
	player_platform_collision()
	player_movement()
	player_jump()
	apply_player_gravity()
	apply_player_velocity()

	rigidbody_platform_collision()
	apply_rigidbody_gravity()
	apply_rigidbody_velocity()
}

collision :: proc() {
	player_platform_collision()

}

collider_nearest_point :: proc(c: Static_Collider, v: Vec2) -> Vec2 {
	return l.clamp(v, c.min, c.max)
}

rectangle_nearest_point :: proc(r: Rectangle, t, v: Vec2) -> Vec2 {
	min, max := t - (r.extents) / 2, t + (r.extents) / 2
	return l.clamp(v, min, max)
}

aabb_overlap :: proc(a_min, a_max, b_min, b_max: Vec2) -> (colliding: bool, push_vector: Vec2) {
	a_center := (a_min + a_max) / 2
	b_center := (b_min + b_max) / 2

	d := b_center - a_center

	a_half := a_max - a_min
	b_half := b_max - b_min

	half := a_half + b_half

	pen_x := half.x - d.x
	pen_y := half.y - d.y

	return
}

apply_rigidbody_velocity :: proc() {
	for &rb in rigidbodies {
		rb.collider.translation += rb.velocity * TICK_RATE
	}
}

apply_rigidbody_gravity :: proc() {
	for &rb in rigidbodies {
		rb.velocity.y += falling_gravity * TICK_RATE
	}
}
