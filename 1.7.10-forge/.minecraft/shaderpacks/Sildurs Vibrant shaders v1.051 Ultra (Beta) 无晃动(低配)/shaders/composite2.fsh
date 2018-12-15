#version 120


varying vec4 texcoord;
uniform sampler2D gaux2;
uniform float aspectRatio;

void main() {
//Bloom
const float rMult = 0.0022;
const int nSteps = 21;


int center = (nSteps-1)/2;
float radius = center*rMult;

vec3 blur = vec3(0.0);
float tw = 0.0;

float sigma = 0.25;
float A = 1.0/sqrt(2.0*3.14159265359*sigma);


for (int i = 0; i < nSteps; i++) {

float dist = (i-float(center))/center;

float weight = A*exp(-(dist*dist)/(2.0*sigma));

blur += pow(texture2D(gaux2,texcoord.xy + rMult*vec2(1.0,aspectRatio)*vec2(i-center,0.0)).rgb,vec3(2.2))*weight;
tw += weight;
}
blur /= tw;
blur = pow(blur,vec3(1.0/2.2));
/* DRAWBUFFERS:3 */
	gl_FragData[0] = vec4(blur,1.0);
}
