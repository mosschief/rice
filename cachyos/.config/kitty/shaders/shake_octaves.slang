#language slang 2026

// Octave-noise x/y screen-shake on BEL. Adapted from
// https://jcd.pub/2026/11/04/screenshake-shaders-for-kitty/
import kitty_custom_shader_types;

static const float BASE_FREQUENCY_HZ = 5.0;
static const float BASE_X_PIXELS = 30.0;
static const float BASE_Y_PIXELS = 30.0;
static const float3 OCTAVE_WEIGHTS = float3(0.03, 1.0, 2.4);
static const float3 OCTAVE_FALLOFF_EXPONENTS = float3(4.0, 2.0, 1.0);

uint hash_bits(uint value) {
    value ^= value >> 16;
    value *= 0x7feb352du;
    value ^= value >> 15;
    value *= 0x846ca68bu;
    value ^= value >> 16;
    return value;
}

float gradient(int point, uint seed) {
    uint bits = hash_bits(uint(point) ^ seed);
    return float(bits & 0xffffu) / 32767.5 - 1.0;
}

float gradient_noise(float time, uint seed) {
    float point = floor(time);
    float phase = time - point;
    float blend = phase * phase * (3.0 - 2.0 * phase);

    float left = gradient(int(point), seed) * phase;
    float right = gradient(int(point) + 1, seed) * (phase - 1.0);

    return 2.0 * lerp(left, right, blend);
}

float octave_noise(float time, uint seed, float progress) {
    float3 octaves = float3(
        gradient_noise(time, seed),
        gradient_noise(2.0 * time, seed ^ 0x9e3779b9u),
        gradient_noise(4.0 * time, seed ^ 0x85ebca6bu)
    );
    float total_weight = OCTAVE_WEIGHTS.x + OCTAVE_WEIGHTS.y + OCTAVE_WEIGHTS.z;
    float3 remaining = pow(float3(1.0 - progress), OCTAVE_FALLOFF_EXPONENTS);

    return dot(octaves, OCTAVE_WEIGHTS * remaining) / total_weight;
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float4 rect = d.bell_window_geometry;
    float2 rect_end = rect.xy + rect.zw;

    if (rect.z <= 0.0 || rect.w <= 0.0 ||
        any(t.pos < rect.xy) || any(t.pos >= rect_end)) {
        return color;
    }

    float time = d.timestamp * BASE_FREQUENCY_HZ;

    float2 movement = float2(
        octave_noise(time, 0x1337133bu, t.animation_progress),
        octave_noise(time, 0x7f4a7c15u, t.animation_progress)
    );
    float2 pixels = movement * float2(BASE_X_PIXELS, BASE_Y_PIXELS);
    float2 sample_pos = t.pos - pixels / float2(d.viewport_size_pixels);

    float4 sampled = t.backbuffer.Sample(sample_pos);
    return float4(sampled.rgb / max(sampled.a, 1e-6), sampled.a);
}
