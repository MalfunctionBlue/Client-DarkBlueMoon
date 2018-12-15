#version 120

uniform sampler2D texture;

uniform float far;

uniform int fogMode;

varying vec4 color;
varying vec4 texcoord;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

float smoothStep(in float edge0, in float edge1, in float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

//////////////////////////////main//////////////////////////////

void main() {
    // clouds
    float fogFactor = float(GL_EXP == fogMode) * (1.0f - clamp(exp(-1.0f * gl_Fog.density * gl_FogFragCoord), 0.0f, 1.0f));
    fogFactor += float(GL_LINEAR == fogMode) * clamp(1.0f * (gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0f, 1.0f);
    vec4 frag = texture2D(texture, texcoord.xy) * color;

/* DRAWBUFFERS:0346 */
    gl_FragData[0] = frag;
    gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, fogFactor);
    gl_FragData[0].a *= 1.0f - smoothStep(far * 1.7f, far * 2.1f, gl_FogFragCoord); // smooth away clouds far away
    gl_FragData[1] = gl_FragData[0];
    gl_FragData[2] = vec4(0.0f, 0.0f, 0.0f, 0.0f); // x = spec; y = basic, textured(0.0), shadow exit(0.1), lit(0.3), hand(0.4), entity(0.6), ice(0.9), water(1.0); z = torch lightmap; w = opacity
    gl_FragData[3] = vec4(1.0f);    // clouds to composite1.fsh
}

//////////////////////////////main//////////////////////////////
