#version 120

/*
Read my terms of mofification/sharing before changing something below please!
Chocapic13' shaders, derived from SonicEther v10 rc6.
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//go to line 96 for changing sunlight/ambient color balance

varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 sunlight_color;
varying vec3 ambient_color;
varying float handItemLight;

uniform vec3 skyColor;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;
uniform int heldItemId;
uniform int heldBlockLightValue;
uniform float rainStrength;
uniform float wetness;
/*
const ivec4 ToD[25] = ivec4[25](ivec4(0,3,5,12), //hour,r,g,b
								ivec4(1,3,5,12),
								ivec4(2,3,5,12),
								ivec4(3,3,5,12),
								ivec4(4,3,5,12),
								ivec4(5,3,5,12),
								ivec4(6,120,80,35),
								ivec4(7,200,169,100),
								ivec4(8,215,190,107),
								ivec4(9,220,200,110),
								ivec4(10,220,205,135),
								ivec4(11,230,215,160),
								ivec4(12,230,215,160),
								ivec4(13,230,230,150),
								ivec4(14,220,205,125),
								ivec4(15,220,200,110),
								ivec4(16,220,200,97),
								ivec4(17,215,195,80),
								ivec4(18,200,190,70),
								ivec4(19,77,67,194),
								ivec4(20,3,5,12),
								ivec4(21,3,5,12),
								ivec4(22,3,5,12),
								ivec4(23,3,5,12),
								ivec4(24,3,5,12));*/
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
/*
255 216 128
*/
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
const ivec4 ToD[25] = ivec4[25](ivec4(0,6,10,24), //hour,r,g,b
								ivec4(1,6,10,24),
								ivec4(2,6,10,24),
								ivec4(3,6,10,24),
								ivec4(4,6,10,24),
								ivec4(5,6,10,24),
								ivec4(6,120,80,35),
								ivec4(7,200,169,100),
								ivec4(8,215,190,107),
								ivec4(9,220,200,110),
								ivec4(10,220,205,135),
								ivec4(11,230,215,160),
								ivec4(12,230,215,160),
								ivec4(13,230,230,150),
								ivec4(14,220,205,125),
								ivec4(15,220,200,110),
								ivec4(16,220,200,97),
								ivec4(17,215,195,80),
								ivec4(18,200,190,70),
								ivec4(19,77,67,194),
								ivec4(20,6,10,24),
								ivec4(21,6,10,24),
								ivec4(22,6,10,24),
								ivec4(23,6,10,24),
								ivec4(24,6,10,24));

////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
const ivec4 ToD2[25] = ivec4[25](ivec4(0,8,20,30), //hour,r,g,b
								ivec4(1,8,20,30),
								ivec4(2,8,20,30),
								ivec4(3,8,20,30),
								ivec4(4,8,20,30),
								ivec4(5,30,75,150),
								ivec4(6,60,160,255),
								ivec4(7,60,160,255),
								ivec4(8,60,160,255),
								ivec4(9,60,160,255),
								ivec4(10,60,160,255),
								ivec4(11,60,160,255),
								ivec4(12,60,160,255),
								ivec4(13,60,160,255),
								ivec4(14,60,160,255),
								ivec4(15,60,160,255),
								ivec4(16,60,160,255),
								ivec4(17,60,160,255),
								ivec4(18,60,160,255),
								ivec4(19,30,75,150),
								ivec4(20,8,20,30),
								ivec4(21,8,20,30),
								ivec4(22,8,20,30),
								ivec4(23,8,20,30),
								ivec4(24,8,20,30));

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;

	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}

	handItemLight = 0.0;
	if (heldItemId == 50) {
		// torch
		handItemLight = 0.2;
	}
	
	else if (heldItemId == 76 || heldItemId == 94) {
		// active redstone torch / redstone repeater
		handItemLight = 0.1;
	}
	
	else if (heldItemId == 89) {
		// lightstone
		handItemLight = 0.6;
	}
	
	else if (heldItemId == 10 || heldItemId == 11 || heldItemId == 51) {
		// lava / lava / fire
		handItemLight = 0.5;
	}
	
	else if (heldItemId == 91) {
		// jack-o-lantern
		handItemLight = 0.6;
	}
	
	
	else if (heldItemId == 327) {
		handItemLight = 0.2;
	}
	
	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;
	
	ivec4 temp = ToD[int(floor(hour))];
	ivec4 temp2 = ToD[int(floor(hour)) + 1];
	
	sunlight_color = mix(vec3(temp.yzw),vec3(temp2.yzw),(hour-float(temp.x))/float(temp2.x-temp.x))/255.0f;
	
	ivec4 tempa = ToD2[int(floor(hour))];
	ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
	
	ambient_color = mix(vec3(tempa.yzw),vec3(tempa2.yzw),(hour-float(tempa.x))/float(tempa2.x-tempa.x))/255.0f;
	
}
