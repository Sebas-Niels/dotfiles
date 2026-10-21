#language slang 2026

// Starfield where every star slowly wanders on its own random, never-repeating path.
//
// Stars live on a grid (one candidate star per cell per layer) and wander around
// their cell's home point, so each pixel only checks the cells within reach.
// Paths are sums of sines with per-star random frequencies, which never line up.

import kitty_custom_shader_types;

static const float PI = 3.14159265359f;

// === TUNING ===
static const float STAR_INTENSITY = 0.42f; // overall brightness, keep low for subtle
static const float STAR_SIZE = 2.3f;       // radius in pixels of the nearest layer
static const float STAR_PRESENCE = 0.4f;   // chance a cell holds a star
static const float CELL_SIZE = 90.0f;      // grid spacing in pixels of the nearest layer
static const float WANDER = 0.8f;          // how far a star roams from home, in cells
static const float MIN_FREQ = 0.02f;       // rad/s of each star's wander, lower is slower
static const float MAX_FREQ = 0.08f;
static const float TEXT_THRESHOLD = 0.15f; // terminal luminance above which stars fade out
static const int LAYERS = 2;
static const float LAYER_SCALE[2] = { 1.0f, 0.6f }; // further layers are smaller, dimmer and slower
static const int REACH = 2; // cells checked each side; must cover 0.5 + WANDER

uint
hashu(uint x) {
    x ^= x >> 16;
    x *= 0x7feb352du;
    x ^= x >> 15;
    x *= 0x846ca68bu;
    x ^= x >> 16;
    return x;
}

float4
rand4(uint seed) {
    uint a = hashu(seed);
    uint b = hashu(a);
    uint c = hashu(b);
    uint e = hashu(c);
    return float4(float(a), float(b), float(c), float(e)) / 4294967295.0f;
}

float
freq(float r) {
    return lerp(MIN_FREQ, MAX_FREQ, r);
}

// Smooth, non-repeating offset in [-1, 1] on each axis
float2
wander(float4 f, float4 ph, float time) {
    float x = sin(time * freq(f.x) + ph.x) + 0.6f * sin(time * freq(f.y) * 1.7f + ph.y);
    float y = sin(time * freq(f.z) + ph.z) + 0.6f * sin(time * freq(f.w) * 1.9f + ph.w);
    return float2(x, y) / 1.6f;
}

// Light from the star of cell `cell` in `layer`, seen at `p` (pixels)
float3
starLight(float2 p, int2 cell, int layer, float cellSize, float depth, float time) {
    uint seed = hashu(uint(cell.x) * 73856093u ^ uint(cell.y) * 19349663u ^ uint(layer) * 83492791u);
    float4 r1 = rand4(seed);
    if (r1.x >= STAR_PRESENCE) return float3(0.0f);
    float4 f = rand4(seed ^ 0x9e3779b9u);
    float4 ph = rand4(seed ^ 0x85ebca6bu) * 2.0f * PI;

    float2 home = (float2(cell) + 0.5f + (r1.yz - 0.5f) * 0.6f) * cellSize;
    float2 starPos = home + wander(f, ph, time * depth) * WANDER * cellSize;

    float size = STAR_SIZE * depth;
    float shape = 1.0f - smoothstep(0.0f, size, length(p - starPos));
    float brightness = lerp(0.3f, 1.0f, r1.w) * depth;
    float3 colour = lerp(float3(1.0f, 0.88f, 0.75f), float3(1.0f, 0.6f, 0.35f), frac(r1.w * 7.31f));
    return colour * shape * brightness;
}

public float4
fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 pixelDims = float2(d.viewport_size_pixels) * t.viewport.zw;
    float2 p = t.pos * pixelDims;
    float time = d.timestamp;

    float3 stars = float3(0.0f);
    [ForceUnroll]
    for (int layer = 0; layer < LAYERS; layer++) {
        float depth = LAYER_SCALE[layer];
        float cellSize = CELL_SIZE * depth;
        int2 base = int2(floor(p / cellSize));
        [ForceUnroll]
        for (int dy = -REACH; dy <= REACH; dy++) {
            [ForceUnroll]
            for (int dx = -REACH; dx <= REACH; dx++) {
                stars += starLight(p, base + int2(dx, dy), layer, cellSize, depth, time);
            }
        }
    }

    float termLum = dot(color.rgb, float3(0.299f, 0.587f, 0.114f));
    float behindText = 1.0f - smoothstep(TEXT_THRESHOLD, TEXT_THRESHOLD + 0.2f, termLum);
    return float4(color.rgb + stars * STAR_INTENSITY * behindText, color.a);
}
