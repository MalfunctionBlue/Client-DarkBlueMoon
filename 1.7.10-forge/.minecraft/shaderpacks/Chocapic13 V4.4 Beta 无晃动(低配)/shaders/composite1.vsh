#version 120

/*
Chocapic13' shaders, read my terms of mofification/sharing before changing something below please!
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 lightVector;
varying vec3 ambient_color;

uniform int worldTime;
uniform float rainStrength;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

	////////////////////sunlight color////////////////////
	////////////////////sunlight color////////////////////
	////////////////////sunlight color////////////////////
	const ivec4 ToD[25] = ivec4[25](ivec4(0,3,5,12), //hour,r,g,b
							ivec4(1,3,5,12),
							ivec4(2,3,5,12),
							ivec4(3,3,5,12),
							ivec4(4,3,5,12),
							ivec4(5,3,5,12),
							ivec4(6,120,80,35),
							ivec4(7,255,195,80),
							ivec4(8,255,200,97),
							ivec4(9,255,200,110),
							ivec4(10,255,205,135),
							ivec4(11,255,215,160),
							ivec4(12,255,215,160),
							ivec4(13,255,215,160),
							ivec4(14,255,205,125),
							ivec4(15,255,200,110),
							ivec4(16,255,200,97),
							ivec4(17,255,195,80),
							ivec4(18,255,190,70),
							ivec4(19,77,67,194),
							ivec4(20,3,5,12),
							ivec4(21,3,5,12),
							ivec4(22,3,5,12),
							ivec4(23,3,5,12),
							ivec4(24,3,5,12));

	////////////////////ambient color////////////////////
	////////////////////ambient color////////////////////
	////////////////////ambient color////////////////////
	const ivec4 ToD2[25] = ivec4[25](ivec4(0,45,60,90), //hour,r,g,b
							ivec4(1,45,60,90),
							ivec4(2,45,60,90),
							ivec4(3,45,60,90),
							ivec4(4,45,60,90),
							ivec4(5,60,75,150),
							ivec4(6,90,120,170),
							ivec4(7,100,140,190),
							ivec4(8,125,170,220),
							ivec4(9,165,220,270),
							ivec4(10,190,235,280),
							ivec4(11,205,250,290),
							ivec4(12,220,250,300),
							ivec4(13,205,250,290),
							ivec4(14,190,235,280),
							ivec4(15,165,220,270),
							ivec4(16,125,170,220),
							ivec4(17,100,140,190),
							ivec4(18,90,120,170),
							ivec4(19,60,75,150),
							ivec4(20,45,60,90),
							ivec4(21,45,60,90),
							ivec4(22,45,60,90),
							ivec4(23,45,60,90),
							ivec4(24,45,60,90));
							
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
		if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}
	
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0;
	
	//sunlight color
	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;

							
	ivec4 temp = ToD[int(floor(hour))];
	ivec4 temp2 = ToD[int(floor(hour)) + 1];
	
	sunlight = mix(vec3(temp.yzw),vec3(temp2.yzw),(hour-float(temp.x))/float(temp2.x-temp.x))/255.0f;
	
	
	ivec4 tempa = ToD2[int(floor(hour))];
	ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
	
	ambient_color = mix(vec3(tempa.yzw),vec3(tempa2.yzw),(hour-float(tempa.x))/float(tempa2.x-tempa.x))/255.0f;
	
	vec3 ambient_color_rain = vec3(0.4, 0.4, 0.4); //rain

	//ambient_color.g *= 1.2;
	ambient_color = mix(ambient_color, ambient_color_rain, rainStrength*0.75)*2.0*ambient_color; //rain

	
}
