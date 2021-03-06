#version 120

/*
Read my terms of mofification/sharing before changing something below please!
Chocapic13' shaders, derived from SonicEther v10 rc6.
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

varying vec4 color;
varying vec4 texcoord;
varying vec3 normal;

uniform sampler2D texture;
uniform int fogMode;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
/* DRAWBUFFERS:024 */
	gl_FragData[0] = texture2D(texture,texcoord.xy)*color;
	gl_FragData[1] = vec4(normal*0.5+0.5,1.0);
	gl_FragData[2] = vec4(1.0, 0.03, 0.0, 1.0);
}