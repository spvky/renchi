package main

import "core:math"
import l "core:math/linalg"

Physics_Collider :: struct {
	translation: Vec2,
	shape:       union {
		Collision_Circle,
		Collision_Rect,
	},
}

Collision_Circle :: struct {
	radius: f32,
}

Collision_Rect :: struct {
	min: Vec2,
	max: Vec2,
}

F_Range :: struct {
	min, max: f32,
}


Simplex :: struct {
	count:      int,
	a, b, c, d: Vec2,
}

rect_vertices :: proc(s: Collision_Rect) -> [4]Vec2 {
	return [4]Vec2{{s.min.x, s.max.y}, {s.min.x, s.min.y}, {s.max.x, s.max.y}, {s.max.x, s.min.y}}
}

overlap :: proc(r1, r2: F_Range) -> bool {
	return r1.min <= r2.max && r2.min <= r1.max
}

find_max_in_direction :: proc(c: Physics_Collider, d: Vec2) -> Vec2 {
	point: Vec2
	switch s in c.shape {
	case Collision_Rect:
		vertices := rect_vertices(s)

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

project :: proc(c: Physics_Collider, d: Vec2) -> F_Range {
	min, max: f32
	switch s in c.shape {
	case Collision_Rect:
		v := rect_vertices(s)
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

sat :: proc(s1, s2: Physics_Collider) -> (colliding: bool) {
	// Only doing AABBs at the moment, but if I start handling rotation these will have to be calculated based on rotation
	axes := [2]Vec2{{1, 0}, {0, 1}}
	smallest: Vec2
	smallest_overlap: f32

	for a in axes {
		p1 := project(s1, a)
		p2 := project(s2, a)
		if overlap(p1, p2) {
			return false
		} else {
			//
		}
	}
	return true
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
