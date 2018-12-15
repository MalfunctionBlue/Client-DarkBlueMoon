#version 120

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;

uniform float frameTimeCounter;

varying mat3 tbnMatrix;

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 color;

varying vec3 lightVector;

varying float translucent;
varying float isglass;

//////////////////////////////main//////////////////////////////

void main() {
    vec3 bump = texture2D(normals, texcoord.xy).rgb * 2.0f - 1.0f;
    vec3 frag = tbnMatrix * bump;
    
    float dirtest = translucent + isglass + step(translucent + isglass, 0.02f) * (0.6f - 0.5f * step(dot(frag, lightVector), -0.02f)); // translucent(0.3), ice(0.9), shadowexit(0.1), entity(0.6)

    float flicker = (sin(3.142f * (sin(4.935f * frameTimeCounter) + sin(1.571f * frameTimeCounter))) * 0.015f + 0.985f) * lmcoord.s;
    
/* DRAWBUFFERS:01234 */
    gl_FragData[0] = vec4(vec3(clamp(lmcoord.t + lmcoord.s, 0.25f, 1.0f)), 1.0f) * texture2D(texture, texcoord.xy) * color;
    gl_FragData[1] = texture2D(specular, texcoord.xy);
    gl_FragData[2] = vec4(frag * 0.5f + 0.5f, 1.0f);
    gl_FragData[3] = gl_FragData[0];
    gl_FragData[4] = vec4(0.0f, dirtest, flicker, 1.0f); // x = spec; y = basic, textured(0.0), shadow exit(0.1), lit(0.3), hand(0.4), entity(0.6), ice(0.9), water(1.0); z = torch lightmap; w = opacity
}

//////////////////////////////main//////////////////////////////
