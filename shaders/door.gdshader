shader_type canvas_item;
render_mode unshaded;

instance uniform float open_progress : hint_range(0.0, 1.0) = 0.0;

uniform vec4 door_colour : source_color = vec4(0.68, 0.21, 0.29, 1.0);
uniform vec4 scan_colour : source_color = vec4(0.58, 0.90, 1.0, 1.0);

uniform vec2 door_size = vec2(28.0, 160.0);

varying vec2 local_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 uv = (local_pos + door_size * 0.5) / door_size;
	float t = TIME;
	float progress = open_progress;
	
	vec3 colour = door_colour.rgb;
	
	float side_shadow = abs(uv.x - 0.5) * 2.0;
	colour *= 1.0 - side_shadow * 0.35;
	
	float panel_lines = 1.0 - smoothstep(0.0, 0.08, fract(uv.y * 16.0));
	colour *= 1.0 - panel_lines * 0.18;
	
	float highlight = exp(-pow((uv.x - 0.35) * 8.0, 2.0));
	colour += vec3(0.10) * highlight;
	
	float cutoff = 1.0 - progress;
	float transition = sin(progress * PI);
	float row = floor(uv.y * 48.0);
	float frame = floor(t * 25.0);
	float row_noise = hash(vec2(row, frame));
	float distortion = (row_noise - 0.5) * 0.10 * transition;
	
	float visibility = 1.0;
	if (progress > 0.999) {
		visibility = 0.0;
	} else if (progress > 0.001) {
		visibility = 1.0 - smoothstep(cutoff - 0.025, cutoff + 0.025, uv.y + distortion);
	}
	
	float edge_distance = abs(uv.y - cutoff);
	float scanline = exp(-pow(edge_distance * 45.0, 2.0));
	scanline *= transition;
	colour += scan_colour.rgb * scanline * 0.85;
	
	float interference = row_noise * 2.0 - 1.0;
	colour += vec3(interference) * transition * 0.12;
	
	float flicker = 0.085 + 0.15 + sin(t * 55.0);
	colour *- mix(1.0, flicker, transition);
	
	COLOR = vec4(clamp(colour, 0.0, 1.0), visibility);
}
