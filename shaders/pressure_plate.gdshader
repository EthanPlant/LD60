shader_type canvas_item;
render_mode unshaded;

instance uniform float activated : hint_range(0.0, 1.0) = 0.0;

instance uniform float press_flash : hint_range(0.0, 1.0) = 0.0;

uniform vec4 idle_colour : source_color = vec4(0.85, 0.53, 0.20, 1.0);

uniform vec4 active_colour : source_color = vec4(0.30, 0.88, 0.52, 1.0);

// Match the Polygon2D's local dimensions
uniform vec2 plate_size = vec2(60.0, 10.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 uv = (local_pos + plate_size * 0.5) / plate_size;
	float t = TIME;
	
	vec3 base = mix(idle_colour.rgb, active_colour.rgb, activated);
	
	float top_highlight = 1.0 - smoothstep(0.0, 0.3, uv.y);
	float bottom_shadow = smoothstep(0.65, 1.0, uv.y);
	base *= 0.78 + top_highlight * 0.28 - bottom_shadow * 0.2;
	
	float edge_distance = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float border = 1.0 - smoothstep(0.0, 0.07, edge_distance);
	base += border * vec3(0.12);
	
	float signal_pos = fract(t * 0.75);
	float signal = exp(-pow((uv.x - signal_pos) * 16.0, 2.0));
	base += signal * activated * vec3(0.28, 0.55, 0.34);
	
	float pulse = 0.88 + 0.12 * sin(t * 6.0);
	base *= mix(1.0, pulse, activated * 0.45);
	
	float flash_pattern = 0.7 + 0.3 * sin(uv.x * 28.0);
	base += press_flash * flash_pattern * vec3(0.40, 0.55, 0.30);
	
	COLOR = vec4(clamp(base, 0.0, 1.0), 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
