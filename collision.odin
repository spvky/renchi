package main

import "core:log"
import "core:math"
import l "core:math/linalg"

Physics_Collider :: struct {
	translation: Vec2,
	shape:       Collider_Shape,
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

rect_vertices :: proc(t: Vec2, s: Collision_Rect) -> [4]Vec2 {
	half := s.extents / 2
	return [4]Vec2 {
		t + {half.x, half.y},
		t + {half.x, -half.y},
		t + {-half.x, -half.y},
		t + {-half.x, half.y},
	}
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

gjk :: proc(s1, s2: Physics_Collider) -> bool {
	iter: int
	simp: Simplex
	d := s1.translation - s2.translation
	if d.x == 0 && d.y == 0 {
		d.x = 1
	}
	update_simplex(&simp, support(s1, s2, d))

	if l.dot(simp.a, d) <= 0 {
		return false
	}

	d = -simp.a

	for {
		iter += 1
		update_simplex(&simp, support(s1, s2, d))

		if l.dot(simp.a, d) <= 0 {
			return false
		}

		ao := -simp.a

		if simp.count < 2 {

		}

	}
}

player_platform_collision :: proc() {
	player := &world.player
	player_feet := player.translation + Vec2{0, 0.55}
	foot_collision: bool
	for collider in colliders {
		nearest_point := collider_nearest_point(collider, player.translation)
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
		if l.distance(nearest_point, player_feet) < 0.06 {
			foot_collision = true
		}
	}
	if foot_collision {
		player.state = .Grounded
	} else {
		player.state = .Airborne
	}
}

rigidbody_platform_collision :: proc() {
	for &rb in rigidbodies {
		// Broad phase filter here
		for collider in colliders {
			if colliding, mtv := static_sat(collider, rb.collider); colliding {
				log.debugf("COLLISION: %v", mtv)
				rb.collider.translation -= (mtv.normal * mtv.depth)
				if math.abs(l.dot(Vec2{0, 1}, mtv.normal)) > 0.7 {
					rb.velocity.y = 0
				}
			}
		}
	}
}
