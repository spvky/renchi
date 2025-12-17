package main

import "core:log"
import rl "vendor:raylib"

Lighting :: struct {
	lights:  [16]Light,
	count:   int,
	ambient: Vec4,
}

Light :: struct {
	type:           Light_Type,
	enabled:        bool,
	position:       Vec3,
	target:         Vec3,
	color:          Vec4,
	// Shader locs
	enabledLoc:     i32,
	typeLoc:        i32,
	positionLoc:    i32,
	targetLoc:      i32,
	colorLoc:       i32,
	attenuationLoc: i32,
}

Light_Type :: enum u8 {
	Directional = 0,
	Point       = 1,
}

create_point_light :: proc(
	position: Vec3,
	color: Vec4 = {1, 1, 1, 1},
) -> (
	light_index: int,
	ok: bool,
) {
	if world.lighting.count < 16 {
		i := int(world.lighting.count)
		light := Light {
			enabled  = true,
			type     = .Point,
			position = position,
			color    = color,
		}
		light.enabledLoc = rl.GetShaderLocation(
			assets.lighting_shader,
			rl.TextFormat("lights[%i].enabled", i),
		)
		light.typeLoc = rl.GetShaderLocation(
			assets.lighting_shader,
			rl.TextFormat("lights[%i].type", int(i)),
		)
		light.positionLoc = rl.GetShaderLocation(
			assets.lighting_shader,
			rl.TextFormat("lights[%i].position", i),
		)
		light.targetLoc = rl.GetShaderLocation(
			assets.lighting_shader,
			rl.TextFormat("lights[%i].target", i),
		)
		light.colorLoc = rl.GetShaderLocation(
			assets.lighting_shader,
			rl.TextFormat("lights[%i].color", i),
		)
		world.lighting.lights[i] = light
		update_light_values(&world.lighting.lights[i])
		world.lighting.count += 1
		light_index = i
		ok = true
	} else {
		log.warn("Cannot create light, maximum of 16 lights has already been reached")
		light_index = -1
	}
	return
}

set_light_position :: proc(light: ^Light, position: Vec3) {
	light.position = position
	update_light_values(light)
}

update_light_values :: proc(light: ^Light) {
	rl.SetShaderValue(assets.lighting_shader, light.enabledLoc, &light.enabled, .INT)
	rl.SetShaderValue(assets.lighting_shader, light.typeLoc, &light.type, .INT)

	rl.SetShaderValue(assets.lighting_shader, light.positionLoc, &light.position, .VEC3)
	rl.SetShaderValue(assets.lighting_shader, light.targetLoc, &light.target, .VEC3)

	rl.SetShaderValue(assets.lighting_shader, light.colorLoc, &light.color, .VEC4)
}

lighting_shader_update :: proc() {
	for i in 0 ..< world.lighting.count {
		update_light_values(&world.lighting.lights[i])
	}
}
