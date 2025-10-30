/*
*/
package main

import "core:math"
import "core:log"
import l "core:math/linalg"

colliders: [dynamic]Collider
rigidbodies: [dynamic]Rigidbody

Rigidbody :: struct {
	translation: Vec2,
	snapshot:    Vec2,
	velocity:    Vec2,
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

init_physics_collections :: proc() {
	log.info("Rigidbodies Initialized")
	rigidbodies = make([dynamic]Rigidbody, 0, 16)
	log.info("Colliders Initialized")
	colliders = make([dynamic]Collider, 0, 64)
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
}

collision :: proc() {
	player_platform_collision()

}

collider_nearest_point :: proc(c: Collider, v: Vec2) -> Vec2 {
	return l.clamp(v, c.min, c.max)
}

rectangle_nearest_point :: proc(r: Rectangle, t,v: Vec2) -> Vec2 {
	min,max := t - (r.extents)/2, t + (r.extents)/2
	return l.clamp(v, min, max)
}

aabb_overlap :: proc(a_min,a_max, b_min, b_max: Vec2) -> (colliding: bool, push_vector: Vec2) {
	a_center := (a_min + a_max)/2
	b_center := (b_min + b_max)/2

	d := b_center - a_center

	a_half := a_max - a_min
	b_half := b_max - b_min

	half := a_half + b_half

	pen_x := half.x - d.x
	pen_y := half.y - d.y
	
	return
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

get_collision :: proc(rb: ^Rigidbody, c: Collider) -> (colliding: bool, collision: Collision_Data ) {
	switch v in rb.shape {
	case Circle:
	case Rectangle:
		c_nearest := collider_nearest_point(c, rb.translation)
		// rb_nearest := rectangle_nearest_point(v, rb.translation, c_neares
	}
	return
}

rigidbody_platform_collision :: proc() {
	for &rb in rigidbodies {
	rb_feet := rb.translation + Vec2{0, 0.55}
	foot_collision: bool
	for collider in colliders {
		nearest_point := collider_nearest_point(collider, rb.translation)
		// if l.distance(nearest_point, rb.translation) < rb.radius {
			collision_vector := rb.translation - nearest_point
			collision_normal := l.normalize0(collision_vector)
			// pen_depth := rb.radius - l.length(collision_vector)
			mtv := collision_normal * pen_depth

			rb.translation += mtv
			x_dot := math.abs(l.dot(collision_normal, Vec2{1, 0}))
			y_dot := math.abs(l.dot(collision_normal, Vec2{0, 1}))
			if x_dot > 0.7 {
				rb.velocity.x = 0
			}
			if y_dot > 0.7 {
				rb.velocity.y = 0
			}
		// }
		if l.distance(nearest_point, rb_feet) < 0.06 {
			foot_collision = true
		}
	}
	if foot_collision {
	} else {
	}
}
}
