#version 120

uniform sampler2D texture;

uniform float frameTimeCounter;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;

varying vec3 tangent;
varying vec3 binormal;
varying vec3 normal;
varying vec3 worldpos;

varying float viewdistance;
varying float iswater;
varying float icewater;

vec3 stokes(in float ka, in vec3 k, in vec3 g) {
    // ka = wave steepness, k = displacements, g = gradients / wave number
    float theta = k.x + k.z + k.t;
    float s = ka * (sin(theta) + ka * sin(2.0f * theta));
    return vec3(s * g.x, s * g.z, g.t);  // (-deta/dx, -deta/dz, scale)
}

vec3 waves1() {
    float scale = 8.0f / (viewdistance * viewdistance);
    vec3 gg = vec3(scale, 3600.0f, scale);
    vec3 gk = vec3(viewdistance * 6.0f, frameTimeCounter * -6.0f, 0.0f);
    vec3 gwave = stokes(6.0f, gk, gg);
    return normalize(gwave);
}

vec3 waves2() {
    vec3 gg = vec3(1.897f, 320.0f, 0.632f - 0.75f * 0.33f * cos(worldpos.z * 0.33f));
    vec3 gk = vec3(worldpos.x * 1.897f, frameTimeCounter * 4.0f, worldpos.z * -0.632f - 0.75f * sin(worldpos.z * 0.33f));
    vec3 gwave = stokes(2.0f, gk, gg);
    
    vec3 cg = vec3(2.846f + 1.2f * cos(worldpos.x * 0.6f), 540.0f, 0.949f);
    vec3 ck = vec3(worldpos.x * 2.846f + 2.0f * sin(worldpos.x * 0.6f), frameTimeCounter * 5.0f + 0.2f, worldpos.z * 0.949f);
    vec3 cwave = stokes(1.6f, ck, cg);
    
    return normalize(gwave + cwave);
}

vec3 waves3() {
    vec3 gg = vec3(0.949f, 50.0f, 0.316f + 0.75f * 0.33f * cos(worldpos.z * 0.33f));
    vec3 gk = vec3(worldpos.x * 0.949f, frameTimeCounter * 4.0f, worldpos.z * -0.316f + 0.75f * sin(worldpos.z * 0.33f));
    vec3 gwave = stokes(1.2f, gk, gg);
    
    vec3 cg = vec3(1.423f + 0.7f * cos(worldpos.x * 0.7f), 120.0f, 0.474f);
    vec3 ck = vec3(worldpos.x * 1.423f + 1.0f * sin(worldpos.x * 0.7f), frameTimeCounter * 5.0f + 0.1f, worldpos.z * 0.474f);
    vec3 cwave = stokes(1.0f, ck, cg);
    
    return normalize(gwave + cwave);
}

float smoothStep(in float edge0, in float edge1, in float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

//////////////////////////////main//////////////////////////////

void main() {
    vec4 frag1 = vec4(normal * 0.5f + 0.5f, 1.0f);
    vec4 frag2;
    vec4 frag3 = frag2 = frag1;
    vec4 tex = texture2D(texture, texcoord.xy);
    if (iswater > 0.9f) {
        tex = mix(tex, vec4(0.02f, 0.03f, 0.14f, 0.85f), 0.5f); // Tint water texture with standard color
        mat3 tbnMatrix = mat3(tangent, binormal, normal);
        vec4 bump1 = vec4(tbnMatrix * waves1() * 0.5f + 0.5f, 1.0f);
        vec4 bump2 = vec4(tbnMatrix * waves2() * 0.5f + 0.5f, 1.0f);
        frag2 = mix(bump1, bump2, 0.5f + 0.5f * smoothStep(5.0f, 10.0f, viewdistance));
        vec3 bump3 = waves3();
        frag3 = vec4(tbnMatrix * bump3 * 0.5f + 0.5f, 1.0f);
    }
    
/* DRAWBUFFERS:01234 */
    gl_FragData[0] = vec4(vec3(clamp(lmcoord.t + lmcoord.s, 0.25f, 1.0f)), 1.0f) * tex * color;
    gl_FragData[1] = frag1; // Reflection heavily bump normal
    gl_FragData[2] = mix(frag2, frag3, smoothStep(20.0f, 36.0f, viewdistance)); // frag3 - fewer waves
    gl_FragData[3] = gl_FragData[0];
    gl_FragData[4] = vec4(0.0f, icewater, lmcoord.s, 1.0f); // x = spec; y = basic, textured(0.0), shadow exit(0.1), lit(0.3), hand(0.4), entity(0.6), ice(0.9), water(1.0); z = torch lightmap; w = 1.0 opacity
}

//////////////////////////////main//////////////////////////////
