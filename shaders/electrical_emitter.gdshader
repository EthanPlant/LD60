
shader_type canvas_item;
render_mode unshaded;

instance uniform float powered :
    hint_range(0.0, 1.0) = 1.0;

// 0 = top emitter, 1 = bottom emitter.
instance uniform float flip_y :
    hint_range(0.0, 1.0) = 0.0;

varying vec2 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    vec2 p = local_pos;

    // The bottom emitter points upwards.
    if (flip_y > 0.5) {
        p.y = -p.y;
    }

    float ax = abs(p.x);

    // Cut a narrower electrode nozzle out of
    // the lower edge of our rectangle.
    if (p.y > 5.0 && ax > 12.0) {
        discard;
    }

    // Bevel the housing's outer corners.
    if (
        p.y < -6.0 &&
        ax + (-p.y - 6.0) > 22.0
    ) {
        discard;
    }

    // Brushed steel housing.
    float grain = fract(
        sin(dot(
            floor(p * 1.7),
            vec2(12.9898, 78.233)
        )) * 43758.5453
    );

    vec3 col = vec3(0.18, 0.26, 0.32);
    col += (grain - 0.5) * 0.045;

    // Slight directional metallic shading.
    col += (5.0 - p.y) * 0.003;

    // Bright upper bevel.
    float top_highlight = 1.0 - smoothstep(
        -11.0, -7.0, p.y
    );

    col += vec3(0.12, 0.17, 0.19)
        * top_highlight;

    // Recessed seam separating the housing
    // from the electrode assembly.
    float seam = 1.0 - smoothstep(
        0.0, 1.5,
        abs(p.y - 3.5)
    );

    col *= 1.0 - seam * 0.38;

    // Diagonal hazard stripes on the housing.
    float warning_zone =
        (1.0 - smoothstep(-7.0, -5.0, p.y))
        * smoothstep(4.0, 7.0, ax);

    float stripe = step(
        0.5,
        fract((p.x + p.y * 0.8) / 7.0)
    );

    col = mix(
        col,
        vec3(0.76, 0.48, 0.16),
        warning_zone * stripe * 0.82
    );

    // Two dark fastening bolts.
    float bolt_l = length(
        p - vec2(-16.0, -2.5)
    );

    float bolt_r = length(
        p - vec2(16.0, -2.5)
    );

    float bolts = max(
        1.0 - smoothstep(1.2, 2.0, bolt_l),
        1.0 - smoothstep(1.2, 2.0, bolt_r)
    );

    col = mix(
        col,
        vec3(0.035, 0.065, 0.08),
        bolts
    );

    // Dark insulating material around the
    // actual electrical contact.
    float nozzle = step(5.0, p.y);

    col = mix(
        col,
        vec3(0.075, 0.13, 0.18),
        nozzle * 0.85
    );

    // Cyan light spilling over the nozzle.
    float pulse = 0.86
        + 0.14 * sin(TIME * 16.0);

    float glow = 1.0 - smoothstep(
        1.0, 15.0,
        length((p - vec2(0.0, 8.0))
            * vec2(0.8, 1.0))
    );

    col += vec3(0.07, 0.36, 0.43)
        * glow * powered * pulse;

    // Bright central electrode.
    float contact_x = 1.0 - smoothstep(
        7.0, 10.0, ax
    );

    float contact_y = 1.0 - smoothstep(
        2.0, 5.0,
        abs(p.y - 9.0)
    );

    float contact = contact_x * contact_y;

    vec3 contact_color = mix(
        vec3(0.16, 0.28, 0.32),
        vec3(0.55, 1.0, 1.0) * pulse,
        powered
    );

    col = mix(
        col,
        contact_color,
        contact * 0.95
    );

    // Small flickering arc inside the contact.
    float arc_x = sin(
        p.y * 0.9 + TIME * 19.0
    ) * 3.0;

    float arc = 1.0 - smoothstep(
        0.4, 1.5,
        abs(p.x - arc_x)
    );

    float arc_region =
        step(7.0, p.y) * powered;

    col += vec3(0.55, 0.9, 1.0)
        * arc * arc_region * pulse;

    // Status lights: amber when off,
    // cyan when powered.
    float led_l = length(
        p - vec2(-16.0, 2.0)
    );

    float led_r = length(
        p - vec2(16.0, 2.0)
    );

    float leds = max(
        1.0 - smoothstep(1.5, 2.8, led_l),
        1.0 - smoothstep(1.5, 2.8, led_r)
    );

    vec3 led_color = mix(
        vec3(0.85, 0.32, 0.10),
        vec3(0.32, 1.0, 0.90),
        powered
    );

    col = mix(col, led_color, leds);

    COLOR = vec4(col, 1.0);
}
