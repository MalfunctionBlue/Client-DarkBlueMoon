#version 120

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;

varying mat3 tbnMatrix;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

//////////////////////////////main//////////////////////////////

void main() {
    vec3 bump = texture2D(normals, texcoord.xy).rgb * 2.0f - 1.0f;
    vec4 frag2 = vec4(tbnMatrix * bump * 0.5f + 0.5f, 1.0f);
    
/* DRAWBUFFERS:0124 */
    gl_FragData[0] = vec4(vec3(clamp(lmcoord.t + lmcoord.s, 0.25f, 1.0f)), 1.0f) * texture2D(texture, texcoord.xy) * color;
    gl_FragData[1] = texture2D(specular, texcoord.xy);
    gl_FragData[2] = frag2;
    gl_FragData[3] = vec4(0.0f, 0.4f, lmcoord.s, 1.0f); // x = spec; y = basic, textured(0.0), shadow exit(0.1), lit(0.3), hand(0.4), entity(0.6), ice(0.9), water(1.0); z = torch lightmap; w = opacity
}

//////////////////////////////main//////////////////////////////
