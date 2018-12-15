#version 120

uniform sampler2D texture;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

float smoothStep(in float edge0, in float edge1, in float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

//////////////////////////////main//////////////////////////////

void main() {
    vec4 frag = vec4(vec3(clamp(lmcoord.t + lmcoord.s, 0.25f, 1.0f)), 1.0f) * texture2D(texture,texcoord.xy) * color;
/* DRAWBUFFERS:034 */
    gl_FragData[0] = frag;
    gl_FragData[1] = vec4(frag.xyz, frag.w * smoothStep(10.0f, 14.0f, gl_FogFragCoord));   // remove nearby smoke in reflection
    gl_FragData[2] = vec4(0.0f, 0.3f, lmcoord.s, 0.0f); // x = spec; y = basic, textured(0.0), shadow exit(0.1), lit(0.3), hand(0.4), entity(0.6), ice(0.9), water(1.0); z = torch lightmap; w = opacity = 0.0f for smokeless
}

//////////////////////////////main//////////////////////////////
