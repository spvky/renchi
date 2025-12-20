package main


New_Entity :: struct {
	tag:               Entity_Tag,
	state_flags:       bit_set[Entity_State_Flag;u8],
	interaction_flags: bit_set[Entity_Interaction_Flag;u8],
	rigidbody:         New_Rigidbody,
	meta:              rawptr,
}

New_Rigidbody :: struct {
	translation: Vec2,
	snapshot:    Vec2,
	rotation:    f32,
	shape:       Collider_Shape,
	rb_flags:    bit_set[Rigidbody_Flags;u8],
}

Rigidbody_Flags :: enum u8 {
	Sensor,
	Rot_Lock,
	X_Trans_Lock,
	Y_Trans_Lock,
	Static,
}
