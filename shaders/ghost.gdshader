shader_type canvas_item;

uniform vec4 ghost_color : source_color = vec4(0.35, 0.85, 1.0, 0.75);

instance uniform float wear : hint_range(0.0, 1.0) = 0.0;

varying vec2 local_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
	
	// Tiny horizontal instability
	float jitter = sin(TIME * 19.0 + VERTEX.y * 0.65);
	
	VERTEX.x += jitter * (0.45 + wear * 1.2);
}

void fragment() {
	// Moving horizontal scanlines
	float scanline = 0.5 + 0.5 * sin(local_pos.y * 2.2 + TIME * 3.0);
	
	// Horizontal signal dropout
	float strip = floor(local_pos.y / 3.0);
	float frame = floor(TIME * 15.0);
	
	float noise = hash(vec2(strip, frame));
	
	float dropout = step(0.96 - wear * 0.14, noise);
	
	// Slight brightness flicker
	float flicker = 0.86 + 0.14 * sin(TIME * 8.0);
	
	float alpha = ghost_color.a;
	
	alpha *= 0.7 + scanline * 0.3;
	alpha *= flicker;
	alpha *= 1.0 - dropout * 0.75;
	
	COLOR.rgb = mix(COLOR.rgb, ghost_color.rgb, 0.9);
	
	COLOR.a *= alpha;
}
