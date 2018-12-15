#version 120


/*
Chocapic13' shaders, read my terms of mofification/sharing before changing something below please!
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/


const int RGBA16 = 3;
const int RGB16 = 2;
const int gnormalFormat = RGB16;
const int compositeFormat = RGBA16;
const int gaux2Format = RGBA16;


const int GL_EXP = 2048;
const int GL_LINEAR = 9729;
const float bump_distance = 64.0;		//bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float pom_distance = 32.0;		//POM render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 0.1;

	
varying vec2 lmcoord;
varying vec4 color;
varying float translucent;
varying vec2 texcoord;
varying vec3 normal;


uniform sampler2D texture;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;





//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {	
	vec4 frag2 = vec4(normal*0.5+0.5, 1.0f);
			
	float dirtest = 0.4;
	
	vec3 lightVector;
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}
	
	dirtest = mix(1.0-0.8*step(dot(frag2.xyz*2.0-1.0,lightVector),-0.02),0.4,float(translucent > 0.01));

	
/* DRAWBUFFERS:024 */

	gl_FragData[0] = texture2D(texture, texcoord.xy) * color;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, dirtest, lmcoord.s, 1.0);

}