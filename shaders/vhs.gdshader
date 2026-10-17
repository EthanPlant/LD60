
shader_type canvas_item;

uniform sampler2D screen_texture :
    hint_screen_texture, repeat_disable, filter_nearest;

uniform float intensity :
    hint_range(0.0, 1.0) = 0.65;

uniform float wear :
    hint_range(0.0, 1.0) = 0.0;

uniform float rewind_amount :
    hint_range(0.0, 1.0) = 0.0;

// Extra art-direction controls.
uniform float chroma_strength :
    hint_range(0.0, 3.0) = 1.0;

uniform float tracking_strength :
    hint_range(0.0, 3.0) = 1.0;

uniform float ghost_strength :
    hint_range(0.0, 1.0) = 0.15;


float hash(vec2 p) {
    return fract(
        sin(dot(p, vec2(127.1, 311.7)))
        * 43758.5453
    );
}


void fragment() {
    vec2 uv = SCREEN_UV;

    float t = TIME;
    float strength = intensity;
    float damage = wear;
    float rewind = rewind_amount;

    // -------------------------------------------
    // 1. ANALOGUE HORIZONTAL WOBBLE
    // -------------------------------------------

    float wobble = (
        sin(uv.y * 18.0 + t * 2.5)
        * 0.0015
        +
        sin(uv.y * 75.0 - t * 5.0)
        * 0.0006
    );

    uv.x += wobble * strength;

    // -------------------------------------------
    // 2. RANDOM HORIZONTAL TEARING
    // -------------------------------------------

    float row = floor(uv.y * 120.0);
    float frame = floor(t * 12.0);

    float tear_chance = hash(
        vec2(row, frame)
    );

    float tear = step(
        0.965 - damage * 0.04 - rewind * 0.10,
        tear_chance
    );

    float tear_direction = (
        hash(vec2(row + 14.0, frame)) * 2.0
        - 1.0
    );

    uv.x += (
        tear
        * tear_direction
        * (0.012 + damage * 0.025 + rewind * 0.05)
        * strength
        * tracking_strength
    );

    // -------------------------------------------
    // 3. ROLLING TRACKING BAND
    // -------------------------------------------

    float band_position = fract(t * 0.16);

    float distance_to_band = abs(
        uv.y - band_position
    );

    float tracking_band = exp(
        -distance_to_band * 55.0
    );

    uv.x += (
        tracking_band
        * sin(t * 13.0)
        * (0.008 + damage * 0.012 + rewind * 0.025)
        * strength
        * tracking_strength
    );

    // -------------------------------------------
    // 4. VHS HEAD-SWITCHING DISTORTION
    // -------------------------------------------

    float head_switch = smoothstep(
        0.90,
        0.99,
        SCREEN_UV.y
    );

    float head_jitter = sin(
        uv.y * 190.0 + t * 24.0
    );

    uv.x += (
        head_switch
        * head_jitter
        * (0.004 + damage * 0.012 + rewind * 0.02)
        * strength
    );

    // Vertical signal instability on rewind.
    uv.y += (
        rewind
        * sin(t * 32.0)
        * 0.015
    );

    uv = clamp(uv, vec2(0.0), vec2(1.0));

    // -------------------------------------------
    // 5. RGB CHANNEL SEPARATION
    // -------------------------------------------

    float chroma_offset = (
        0.0015
        + damage * 0.003
        + rewind * 0.008
    ) * strength * chroma_strength;

    vec2 red_uv = clamp(
        uv + vec2(chroma_offset, 0.0),
        vec2(0.0), vec2(1.0)
    );

    vec2 blue_uv = clamp(
        uv - vec2(chroma_offset, 0.0),
        vec2(0.0), vec2(1.0)
    );

    vec3 color = vec3(
        texture(screen_texture, red_uv).r,
        texture(screen_texture, uv).g,
        texture(screen_texture, blue_uv).b
    );

    // -------------------------------------------
    // 6. ANALOGUE IMAGE GHOSTING
    // -------------------------------------------

    vec2 echo_uv = clamp(
        uv - vec2(
            0.006 + damage * 0.006,
            0.0
        ),
        vec2(0.0),
        vec2(1.0)
    );

    vec3 echo_color = texture(
        screen_texture,
        echo_uv
    ).rgb;

    color = mix(
        color,
        echo_color,
        ghost_strength * strength
    );

    // -------------------------------------------
    // 7. CRT SCANLINES
    // -------------------------------------------

    float scanline = (
        0.5 + 0.5 * sin(
            SCREEN_UV.y * 540.0 * 3.14159265
        )
    );

    color *= (
        1.0 - scanline * 0.28 * strength
    );

    // -------------------------------------------
    // 8. ANIMATED ANALOGUE STATIC
    // -------------------------------------------

    vec2 noise_coordinates = floor(
        SCREEN_UV * vec2(960.0, 540.0)
    );

    float noise = hash(
        noise_coordinates
        + vec2(frame * 13.0, frame * 7.0)
    );

    noise = noise * 2.0 - 1.0;

    float noise_amount = (
        0.13
        + damage * 0.20
        + rewind * 0.35
        + head_switch * 0.20
    );

    color += vec3(
        noise * noise_amount * strength
    );

    // -------------------------------------------
    // 9. ROLLING BRIGHTNESS INTERFERENCE
    // -------------------------------------------

    color *= (
        1.0
        - tracking_band
        * (0.20 + damage * 0.15 + rewind * 0.25)
        * strength
    );

    // Mild temporal flicker.
    float flicker = (
        0.5 + 0.5 * sin(t * 23.0)
    );

    color *= (
        1.0 - flicker * 0.035 * strength
    );

    // -------------------------------------------
    // 10. COLOUR FADING
    // -------------------------------------------

    float luminance = dot(
        color,
        vec3(0.299, 0.587, 0.114)
    );

    color = mix(
        color,
        vec3(luminance),
        (0.10 + damage * 0.20) * strength
    );

    // -------------------------------------------
    // 11. VIGNETTE
    // -------------------------------------------

    vec2 edge = (
        SCREEN_UV - vec2(0.5)
    ) * 2.0;

    float vignette = 1.0 - (
        dot(edge * edge, vec2(0.18))
        * strength
    );

    color *= vignette;

    // -------------------------------------------
    // 12. REWIND WHITEOUT
    // -------------------------------------------

    color += vec3(
        rewind * 0.22 * strength
    );

    COLOR = vec4(
        clamp(color, 0.0, 1.0),
        1.0
    );
}
