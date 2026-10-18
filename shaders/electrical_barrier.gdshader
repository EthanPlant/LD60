shader_type canvas_item;

instance uniform float powered : hint_range(0.0, 1.0) = 1.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float y = local_pos.y;
	
	// Two waves create an irregular moving arc
	float arc = sin(y *  0.15 + TIME * 14.0) * 3.0 + sin(y * 0.38 - TIME * 21.0) * 2.0;
	
	float dist_to_arc = abs(local_pos.x - arc);
	
	// Bright central filament
	float core = 1.0 - smoothstep(0.4, 2.0, dist_to_arc);
	
	// Diffuse electrical glow
	float halo = 1.0 - smoothstep(2.0, 8.0, dist_to_arc);
	
	float brightness = clamp(core + halo * 0.35, 0.0, 1.0);
	
	vec3 electric_colour = mix(vec3(0.25, 0.65, 0.9), vec3(0.9, 0.98, 1.0), core);
	
	// Disabled barriers retain a faint trace
	float alpha = mix(0.08, brightness, powered);
	
	COLOR = vec4(electric_colour, alpha);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
