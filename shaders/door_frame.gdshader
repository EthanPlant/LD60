
shader_type canvas_item;
render_mode unshaded;

// Driven by Door.gd.
// 0 = closed, 1 = open.
instance uniform float open_amount :
    hint_range(0.0, 1.0) = 0.0;

varying vec2 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    vec2 p = local_pos;

    // Cut away the interior.
    // Only the two side rails and top header remain.
    if (abs(p.x) < 14.0 && p.y > -80.0) {
        discard;
    }

    float rail = step(14.0, abs(p.x));
    float header = 1.0 - step(-80.0, p.y);

    // Brushed industrial metal.
    float grain = fract(sin(dot(
        floor(p * 1.4),
        vec2(12.9898, 78.233)
    )) * 43758.5453);

    float brushed = sin(p.y * 1.9) * 0.025;

    vec3 metal = vec3(0.21, 0.28, 0.34);
    metal += (grain - 0.5) * 0.055;
    metal += brushed;

    // Lighter inner lip along both sides.
    float inner_lip =
        1.0 - smoothstep(
            0.0, 1.7,
            abs(abs(p.x) - 14.5)
        );

    metal += vec3(0.12, 0.17, 0.19)
        * inner_lip * rail;

    // Dark outer seam.
    float outer_seam =
        1.0 - smoothstep(
            0.0, 1.2,
            abs(abs(p.x) - 19.5)
        );

    metal *= 1.0 - outer_seam * 0.42;

    // Brighter top header.
    metal += vec3(0.065, 0.08, 0.09) * header;

    // Small hazard stripes near the bottom
    // of each vertical rail.
    float warning_region =
        rail
        * step(35.0, p.y)
        * (1.0 - step(69.0, p.y));

    float stripe = step(
        0.5,
        fract((p.y + p.x * 0.75) / 10.0)
    );

    metal = mix(
        metal,
        vec3(0.75, 0.51, 0.19),
        warning_region * stripe * 0.75
    );

    // Two small fastening bolts.
    float bolt_x =
        1.0 - step(
            1.4,
            abs(abs(p.x) - 17.0)
        );

    float bolt_top =
        1.0 - step(1.4, abs(p.y + 74.0));

    float bolt_bottom =
        1.0 - step(1.4, abs(p.y - 19.0));

    float bolts = bolt_x * max(
        bolt_top,
        bolt_bottom
    );

    metal = mix(
        metal,
        vec3(0.055, 0.085, 0.11),
        bolts
    );

    // Indicator lights on both rails.
    // Red/amber when closed, cyan-green when open.
    float led_x =
        1.0 - step(
            1.5,
            abs(abs(p.x) - 17.0)
        );

    float led_y =
        1.0 - step(
            7.0,
            abs(p.y + 55.0)
        );

    float led_mask = led_x * led_y;

    vec3 closed_color =
        vec3(0.95, 0.36, 0.21);

    vec3 open_color =
        vec3(0.34, 1.0, 0.75);

    vec3 led_color = mix(
        closed_color,
        open_color,
        open_amount
    );

    float pulse = 0.88
        + 0.12 * sin(TIME * 5.0);

    metal = mix(
        metal,
        led_color * pulse,
        led_mask * 0.94
    );

    COLOR = vec4(metal, 1.0);
}
