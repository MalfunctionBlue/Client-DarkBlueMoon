#version 120

/*
Chocapic13' shaders, read my terms of mofification/sharing before changing something below please!
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

varying vec4 color;

uniform int fogMode;

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
	gl_FragData[0] = vec4(color.rgb*vec3(0.75,0.82,1.0),color.a);
	
/* DRAWBUFFERS:04 */
	

	gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[0].rgb = mix(gl_FragData[0].rgb, (gl_Fog.color.rgb), 1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0));

	
}