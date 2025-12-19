package main

import "core:log"
import "core:math"
import l "core:math/linalg"

// TODO: As part of the broad phase, since at this point all colliders except for the player are axis alligned rectangles, concat all relevant colliders within a chunk (probably a collection of adjacent cells) into one list of sets of [4]Vec2, and do collision in one big pass, while indicating which colliders are static for resolution

Physics_Collider :: struct {
	translation: Vec2,
	shape:       Collider_Shape,
}

Collision_Flag :: enum {
	Standable,
	Clingable,
	Oneway,
}

Collider_Shape :: union {
	Collision_Circle,
	Collision_Rect,
}

Collision_Circle :: struct {
	radius: f32,
}

Collision_Rect :: struct {
	extents: Vec2,
}

F_Range :: struct {
	min, max: f32,
}


Simplex :: struct {
	count:      int,
	a, b, c, d: Vec2,
}

Mtv :: struct {
	normal: Vec2,
	depth:  f32,
}

Temp_Collider :: struct {
	points: [4]Vec2,
	flags:  bit_set[Collision_Flag],
}

rect_vertices :: proc(t: Vec2, s: Collision_Rect) -> [4]Vec2 {
	half := s.extents / 2
	return [4]Vec2 {
		t + {half.x, half.y},
		t + {half.x, -half.y},
		t + {-half.x, -half.y},
		t + {-half.x, half.y},
	}
}

// normal from rectangle vertices, assuming counter clockwise order
normals_from_rect_vertices :: proc(vertices: [4]Vec2) -> [2]Vec2 {
	a1 := l.normalize(vertices[0] - vertices[1])
	a1.x, a1.y = -a1.y, a1.x
	a2 := l.normalize(vertices[1] - vertices[2])
	a2.x, a2.y = -a2.y, a2.x
	return [2]Vec2{a1, a2}
}

overlap :: proc(r1, r2: F_Range) -> (colliding: bool, minimum_translation: f32) {
	colliding = r1.min <= r2.max && r2.min <= r1.max
	if !colliding {
		return
	}
	minimum_translation = math.max(0, math.min(r1.max, r2.max) - math.max(r1.min, r2.min))
	return
}

find_max_in_direction :: proc(c: Physics_Collider, d: Vec2) -> Vec2 {
	point: Vec2
	switch s in c.shape {
	case Collision_Rect:
		vertices := rect_vertices(c.translation, s)

		max_dot: f32 = math.F32_MIN
		max_index: int

		for v, i in vertices {
			dot := l.dot(v, d)
			if dot > max_dot {
				max_dot = dot
				max_index = i
			}
		}
		point = vertices[max_index]
	case Collision_Circle:
		point = c.translation + (l.normalize(d) * s.radius)
	}
	return point
}

support :: proc(c1, c2: Physics_Collider, d: Vec2) -> Vec2 {
	return find_max_in_direction(c1, d) - find_max_in_direction(c2, -d)
}

update_simplex :: proc(s: ^Simplex, p: Vec2) {
	using s
	a, b, c, d = p, a, b, c
	count = math.min(count + 1, 4)
}

project_vertices :: proc(v: []Vec2, d: Vec2) -> F_Range {
	v_min := l.dot(v[0], d)
	v_max := v_min
	for i in 1 ..< 4 {
		p := l.dot(v[i], d)
		v_min = min(p, v_min)
		v_max = max(p, v_max)
	}
	return F_Range{v_min, v_max}
}

project :: proc(c: Physics_Collider, d: Vec2) -> F_Range {
	min, max: f32
	switch s in c.shape {
	case Collision_Rect:
		v := rect_vertices(c.translation, s)
		min = l.dot(v[0], d)
		max = min
		for i in 1 ..< 4 {
			p := l.dot(v[i], d)
			min = math.min(p, min)
			max = math.max(p, max)
		}
	case Collision_Circle:
		min_point := c.translation - (s.radius * d)
		max_point := c.translation + (s.radius * d)
		min = l.dot(min_point, d)
		max = l.dot(max_point, d)
	}
	return F_Range{min, max}
}

sat :: proc(s1, s2: Physics_Collider) -> (colliding: bool, mtv: Mtv) {
	// Only doing AABBs at the moment, but if I start handling rotation these will have to be calculated based on rotation
	axes := [2]Vec2{{1, 0}, {0, 1}}
	smallest: Vec2
	smallest_overlap: f32 = math.F32_MAX


	for a in axes {
		p1 := project(s1, a)
		p2 := project(s2, a)
		if collision, overlap_amount := overlap(p1, p2); collision {
			if overlap_amount < smallest_overlap {
				smallest_overlap = overlap_amount
				smallest = a
			}
		} else {
			return
		}
	}
	colliding = true
	mtv = Mtv {
		normal = smallest,
		depth  = smallest_overlap,
	}
	return
}

static_sat :: proc(c: Static_Collider, s: Physics_Collider) -> (colliding: bool, mtv: Mtv) {
	// Only doing AABBs at the moment, but if I start handling rotation these will have to be calculated based on rotation
	axes := [2]Vec2{{1, 0}, {0, 1}}
	smallest: Vec2
	smallest_overlap: f32 = math.F32_MAX

	collider_verts := collider_vertices(c)

	for a in axes {
		p1 := project(s, a)
		p2 := project_vertices(collider_verts[:], a)
		if collision, overlap_amount := overlap(p1, p2); collision {
			if overlap_amount < smallest_overlap {
				smallest_overlap = overlap_amount
				smallest = a
			}
		} else {
			return
		}
	}
	colliding = true
	mtv = Mtv {
		normal = smallest,
		depth  = smallest_overlap,
	}
	return
}

player_temp_collider_collision :: proc() {
	player := &world.player
	player_feet := player.translation + Vec2{0, 0.55}
	player_left_arm := player.translation + Vec2{-0.55, 0}
	player_right_arm := player.translation + Vec2{0.55, 0}
	foot_collision, right_arm_collision, left_arm_collision: bool
	falling := player.velocity.y > 0

	for collider, i in world.temp_colliders {
		nearest_point := temp_collider_nearest_point(collider, player.translation)
		if l.distance(nearest_point, player.translation) < player.radius {
			collision_vector := player.translation - nearest_point
			collision_normal := l.normalize0(collision_vector)
			pen_depth := player.radius - l.length(collision_vector)
			mtv := collision_normal * pen_depth

			player.translation += mtv
			x_dot := math.abs(l.dot(collision_normal, Vec2{1, 0}))
			y_dot := math.abs(l.dot(collision_normal, Vec2{0, 1}))
			if x_dot > 0.7 {
				player.velocity.x = 0
			}
			if y_dot > 0.7 {
				player.velocity.y = 0
			}
		}
		if l.distance(nearest_point, player_feet) < 0.06 && .Standable in collider.flags {
			foot_collision = true
		}
		if falling {
			if l.distance(nearest_point, player_right_arm) < 0.06 && .Clingable in collider.flags {
				right_arm_collision = true
			}
			if l.distance(nearest_point, player_left_arm) < 0.06 && .Clingable in collider.flags {
				left_arm_collision = true
			}
		}
	}
	if foot_collision {
		player_land()
	} else {
		player.state_flags -= {.Grounded}
	}

	if left_arm_collision {
		player.state_flags += {.TouchingLeftWall, .Clinging}
	} else {
		player.state_flags -= {.TouchingLeftWall}
	}

	if right_arm_collision {
		player.state_flags += {.TouchingRightWall, .Clinging}
	} else {
		player.state_flags -= {.TouchingRightWall}
	}

	if !left_arm_collision && !right_arm_collision {
		player.state_flags -= {.Clinging}
	}
}

rigidbody_platform_collision :: proc() {
	for &rb in world.rigidbodies {
		// Broad phase filter here
		for collider in world.colliders {
			if colliding, mtv := static_sat(collider, rb.collider); colliding {
				rb.collider.translation -= (mtv.normal * mtv.depth)
				if math.abs(l.dot(Vec2{0, 1}, mtv.normal)) > 0.7 {
					rb.velocity.y = 0
				}
			}
		}
	}
}

prepare_temp_colliders :: proc() {
	clear(&world.temp_colliders)

	for c in world.colliders {
		append(
			&world.temp_colliders,
			Temp_Collider {
				points = {
					{c.min.x, c.max.y},
					{c.min.x, c.min.y},
					{c.max.x, c.min.y},
					{c.max.x, c.max.y},
				},
				flags = c.flags,
			},
		)
	}

	for r in world.rigidbodies {
		#partial switch v in r.collider.shape {
		case Collision_Rect:
			half := v.extents / 2
			max := r.collider.translation + half
			min := r.collider.translation - half
			temp_col := Temp_Collider {
				points = {{min.x, max.y}, {min.x, min.y}, {max.x, min.y}, {max.x, max.y}},
				flags  = r.flags,
			}
			append(&world.temp_colliders, temp_col)
		}
	}
}
