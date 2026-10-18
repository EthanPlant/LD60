
shader_type canvas_item;
render_mode unshaded;

uniform float signal_speed :
    hint_range(0.0, 4.0) = 1.0;

uniform float brightness :
    hint_range(0.2, 2.0) = 1.0;

varying vec2 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    vec2 p = local_pos;
    float t = TIME * signal_speed;

    // Dark green phosphor background.
    vec3 col = vec3(0.018, 0.13, 0.095);

    // Fine horizontal scanlines.
    float scanline =
        0.5 + 0.5 * sin(p.y * 2.0 - t * 8.0);

    col += vec3(0.012, 0.070, 0.042)
        * scanline;

    // Slow rolling signal band.
    float sweep_y = -32.0 + mod(t * 16.0, 64.0);

    float sweep = 1.0 - smoothstep(
        0.0, 11.0,
        abs(p.y - sweep_y)
    );

    col += vec3(0.025, 0.15, 0.075) * sweep;

    // Glowing side edges.
    float edge_distance = 28.0 - abs(p.x);

    float edge_glow = 1.0 - smoothstep(
        0.0, 10.0,
        edge_distance
    );

    col += vec3(0.045, 0.30, 0.17)
        * edge_glow;

    // Bright inner border.
    float inner_edge = 1.0 - smoothstep(
        0.0, 2.5,
        edge_distance
    );

    col += vec3(0.13, 0.40, 0.25)
        * inner_edge;

    // Three animated directional chevrons.
    for (int i = 0; i < 3; i++) {
        float centre_x = -17.0 + float(i) * 17.0;

        // A right-facing chevron:
        // the point is furthest right at y = 0.
        float chevron_x =
            centre_x + 6.0 - abs(p.y) * 0.65;

        float stroke = 1.0 - smoothstep(
            0.8, 2.0,
            abs(p.x - chevron_x)
        );

        float height_mask = 1.0 - smoothstep(
            8.0, 10.5,
            abs(p.y)
        );

        float chase = 0.30 + 0.70 * pow(
            max(
                0.0,
                sin(t * 4.2 - float(i) * 1.3)
            ),
            2.0
        );

        float arrow = stroke * height_mask * chase;

        col = mix(
            col,
            vec3(0.57, 1.0, 0.76),
            arrow
        );

        // Subtle phosphor bloom around each arrow.
        float halo = 1.0 - smoothstep(
            1.0, 5.0,
            abs(p.x - chevron_x)
        );

        col += vec3(0.015, 0.085, 0.045)
            * halo * height_mask * chase;
    }

    // Very slight electronic noise.
    float noise = fract(
        sin(
            dot(
                floor(p * 1.7 + vec2(t * 12.0, 0.0)),
                vec2(12.9898, 78.233)
            )
        ) * 43758.5453
    );

    col += (noise - 0.5) * 0.025;

    // Gentle signal breathing.
    float pulse = 0.94 + 0.06 * sin(t * 2.5);

    col *= brightness * pulse;

    COLOR = vec4(col, 1.0);
}
