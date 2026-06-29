import Metal

/// Inline shader source used as fallback if the compiled .metal library isn't found.
enum RenderPipeline {
    static let inlineShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct SpriteInstance {
    float2 position;
    float2 size;
    float4 uvRect;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 screenSize;
};

constant float2 corners[4] = { {0,0},{1,0},{0,1},{1,1} };

vertex VertexOut sprite_vertex(
    uint vid [[vertex_id]],
    constant SpriteInstance& inst [[buffer(0)]],
    constant Uniforms& uni [[buffer(1)]]
) {
    float2 corner   = corners[vid];
    float2 topLeft  = inst.position - inst.size * 0.5;
    float2 pointPos = topLeft + corner * inst.size;
    float2 ndc;
    ndc.x =  (pointPos.x / uni.screenSize.x) * 2.0 - 1.0;
    ndc.y = -((pointPos.y / uni.screenSize.y) * 2.0 - 1.0);
    VertexOut out;
    out.position = float4(ndc, 0, 1);
    out.uv = float2(
        inst.uvRect.x + corner.x * inst.uvRect.z,
        inst.uvRect.y + corner.y * inst.uvRect.w
    );
    return out;
}

fragment float4 sprite_fragment(
    VertexOut in [[stage_in]],
    texture2d<float> atlas [[texture(0)]],
    sampler smp [[sampler(0)]]
) {
    float4 color = atlas.sample(smp, in.uv);
    if (color.a < 0.01) discard_fragment();
    return color;
}
"""
}
