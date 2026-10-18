
shader_type canvas_item;
render_mode unshaded;

varying vec2 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    vec2 p = local_pos;

    // Remove the centre, keeping:
    // - 6px side rails
    // - 14px upper header
    if (abs(p.x) < 28.0 && p.y > -25.0) {
        discard;
    }

    float rail = step(28.0, abs(p.x));
    float header = 1.0 - step(-25.0, p.y);

    // Dark brushed metal.
    vec3 metal = vec3(0.19, 0.27, 0.32);

    float grain = fract(
        sin(
            dot(
                floor(p * vec2(1.8, 1.4)),
                vec2(12.9898, 78.233)
            )
        ) * 43758.5453
    );

    metal += (grain - 0.5) * 0.055;

    metal += 0.022 * sin(p.y * 2.0);

    // Slightly brighter header.
    metal += vec3(0.07, 0.10, 0.10) * header;

    // Highlight the inner edges of the side rails.
    float lip = 1.0 - smoothstep(
        0.0, 2.0,
        abs(abs(p.x) - 28.5)
    );

    metal += vec3(0.13, 0.19, 0.18)
        * lip * rail;

    // Dark seam along the outer edges.
    float seam = 1.0 - smoothstep(
        0.0, 1.5,
        abs(abs(p.x) - 33.5)
    );

    metal *= 1.0 - seam * 0.4;

    // Green highlight along the header's inner lip.
    float header_lip = 1.0 - smoothstep(
        0.0, 2.5,
        abs(p.y + 25.0)
    );

    metal += vec3(0.04, 0.18, 0.12)
        * header_lip * header;

    // Industrial diagonal warning stripes
    // near the bottom of each rail.
    float warning_region =
        rail
        * step(8.0, p.y)
        * (1.0 - step(24.0, p.y));

    float stripe = step(
        0.5,
        fract((p.y + p.x * 0.8) / 9.0)
    );

    metal = mix(
        metal,
        vec3(0.40, 0.57, 0.43),
        warning_region * stripe * 0.65
    );

    // Small dark mounting bolts.
    float bolt_x = 1.0 - step(
        1.5,
        abs(abs(p.x) - 31.0)
    );

    float bolt_top = 1.0 - step(
        1.5,
        abs(p.y + 33.0)
    );

    float bolt_bottom = 1.0 - step(
        1.5,
        abs(p.y - 17.0)
    );

    float bolts = bolt_x * max(
        bolt_top, bolt_bottom
    );

    metal = mix(
        metal,
        vec3(0.045, 0.075, 0.09),
        bolts
    );

    // Two permanent green status lights.
    float led_x = 1.0 - step(
        2.0,
        abs(abs(p.x) - 31.0)
    );

    float led_y = 1.0 - step(
        6.0,
        abs(p.y + 10.0)
    );

    float led = led_x * led_y;

    float led_pulse =
        0.82 + 0.18 * sin(TIME * 3.4);

    vec3 led_color =
        vec3(0.35, 1.0, 0.66) * led_pulse;

    metal = mix(
        metal,
        led_color,
        led * 0.95
    );

    COLOR = vec4(metal, 1.0);
}
