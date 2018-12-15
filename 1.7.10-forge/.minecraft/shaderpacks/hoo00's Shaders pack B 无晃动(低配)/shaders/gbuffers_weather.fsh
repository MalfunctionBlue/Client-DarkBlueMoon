#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

//////////////////////////////main//////////////////////////////

void main() {
	vec4 ambient = texture2D(lightmap, lmcoord.st);
    vec4 frag = texture2D(texture, texcoord.st);
    
/* DRAWBUFFERS:5 */
    gl_FragData[0] = frag * color * ambient; // gaux2 - rain
}

//////////////////////////////main//////////////////////////////
