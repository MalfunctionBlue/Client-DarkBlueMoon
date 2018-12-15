#version 120

/*
Chocapic13' shaders, read my terms of mofification/sharing before changing something below please!
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

/* DRAWBUFFERS:0 */

uniform int worldTime;
uniform sampler2D texture;
uniform float rainStrength;

varying vec4 color;
varying vec4 texcoord;

varying vec3 normal;

const int FOGMODE_LINEAR = 9729;
const int FOGMODE_EXP = 2048;

uniform int fogMode;

							
							
void main() {
	
	gl_FragData[0] = color;
	float fogFactor;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0);
		
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0 - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
	} else {
		fogFactor = 1.0;
	}
	gl_FragData[0] = mix(gl_FragData[0],gl_Fog.color,1.0-fogFactor);
	
}