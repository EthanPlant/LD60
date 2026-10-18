shader_type canvas_item;
render_mode unshaded;

instance uniform float movement : hint_range(0.0, 1.0) = 0.0;
instance uniform float airborne : hint_range(0.0, 1.0) = 0.0;
instance uniform float recording : hint_range(0.0, 1.0) = 0.0;
instance uniform float reset_flash : hint_range(0.0, 1.0) = 0.0;

uniform vec4 suit_colour : source_color = vec4(0.95, 0.82, 0.62, 1.0);
uniform vec4 visor_colour : source_color = vec4(0.22, 0.35, 0.43, 1.0);

uniform vec2 player_size = vec2(20.0, 28.0);

varying vec2 local_pos;

float rectangle(vec2 uv, vec2 minimum, vec2 maximum) {
	return (step(minimum.x, uv.x) * step(minimum.y, uv.y) * step(uv.x, maximum.x) * step(uv.y, maximum.y));
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 uv = clamp((local_pos + player_size * 0.5) / player_size, vec2(0.0), vec2(1.0));
	float t = TIME;
	
	vec3 colour = suit_colour.rgb;
	
	colour *= 0.78 + 0.22 * (1.0 - uv.x);
	
	float scanline = 0.5 + 0.5 * sin(uv.y * 28.0 * PI);
	colour *= 1.0 - scanline * 0.08;
	
	float visor = rectangle(uv, vec2(0.14, 0.16), vec2(0.86, 0.36));
	colour = mix(colour, visor_colour.rgb, visor);
	
	float visor_reflection = rectangle(uv, vec2(0.22, 0.21), vec2(0.68, 0.25));
	colour += visor_reflection * vec3(0.14, 0.25, 0.30);
	
	float boots = smoothstep(0.78, 0.81, uv.y);
	colour = mix(colour, vec3(0.20, 0.27, 0.34), boots);
	
	float edge_distance = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float rim = 1.0 - smoothstep(0.0, 0.09, edge_distance);
	colour += rim * vec3(0.12, 0.09, 0.05);
	
	colour += rim * airborne * vec3(0.06, 0.23, 0.30);
	
	float reflection_position = fract(t * 1.2);
	float reflection = exp(-pow((uv.x - reflection_position) * 12.0, 2.0));
	colour += reflection * movement * vec3(0.16, 0.14, 0.08);
	
	float led = rectangle(uv, vec2(0.68, 0.07), vec2(0.88, 0.18));
	float led_pulse = 0.65 + 0.35 * sin(t * 11.0);
	colour = mix(colour, vec3(1.0, 0.12, 0.10), led * recording * led_pulse);
	
	colour += rim * recording * vec3(0.16, 0.025, 0.015);
	
	colour = mix(colour, vec3(1.0, 0.98, 0.90), reset_flash * 0.90);
	
	COLOR = vec4(clamp(colour, 0.0, 1.0), 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
