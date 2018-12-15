#version 120

//go to line 96 for changing sunlight/ambient color balance

varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 specMultiplier;
varying vec3 heldLightSpecMultiplier;
varying vec3 sunlight_color;
varying vec3 ambient_color;
varying float heldLightMagnitude;
varying float TimeMidnight;
varying float TimeSunset;
varying float TimeNoon;
varying float TimeSunrise;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;
uniform int heldItemId;
uniform int heldBlockLightValue;
uniform float rainStrength;
uniform float wetness;

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0;

	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
		specMultiplier = vec3(1.0, 1.0, 1.0);
	}
	
	else {
		lightVector = normalize(moonPosition);
		specMultiplier = vec3(0.5, 0.5, 0.5);
	}
	
	specMultiplier *= clamp(abs(float(worldTime) / 500.0 - 46.0), 0.0, 1.0) * clamp(abs(float(worldTime) / 500.0 - 24.5), 0.0, 1.0);
	
	heldLightMagnitude = float(heldBlockLightValue);

	if (heldItemId == 50) {
		// torch
		heldLightSpecMultiplier = vec3(1.0, 0.9, 0.5);
	}
	
	else if (heldItemId == 76 || heldItemId == 94) {
		// active redstone torch / redstone repeater
		heldLightSpecMultiplier = vec3(1.0, 0.0, 0.0);
	}
	
	else if (heldItemId == 89) {
		// lightstone
		heldLightSpecMultiplier = vec3(1.0, 1.0, 0.4);
	}
	
	else if (heldItemId == 10 || heldItemId == 11 || heldItemId == 51) {
		// lava / lava / fire
		heldLightSpecMultiplier = vec3(1.0, 0.5, 0.0);
	}
	
	else if (heldItemId == 91) {
		// jack-o-lantern
		heldLightSpecMultiplier = vec3(1.0, 0.5, 0.0);
	}
	
	else if (heldItemId == 326) {
		// water bucket
		heldLightMagnitude = 2.0;
		heldLightSpecMultiplier = vec3(0.0, 0.0, 0.3);
	}
	
	else if (heldItemId == 327) {
		// lava bucket
		heldLightMagnitude = 15.0;
		heldLightSpecMultiplier = vec3(1.0, 0.5, 0.3);
	}
	
	else {
		heldLightSpecMultiplier = vec3(0.0);
	}
	
	////////////////////sunlight color////////////////////
	////////////////////sunlight color////////////////////
	////////////////////sunlight color////////////////////
	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;
	ivec4 ToD[25] = ivec4[25](ivec4(0,15,30,70), //hour,r,g,b
							ivec4(1,15,30,70),
							ivec4(2,15,30,70),
							ivec4(3,15,30,70),
							ivec4(4,15,30,70),
							ivec4(5,50,60,80),
							ivec4(6,255,190,70),
							ivec4(7,255,195,80),
							ivec4(8,255,200,97),
							ivec4(9,255,200,110),
							ivec4(10,255,205,125),
							ivec4(11,255,215,140),
							ivec4(12,255,215,140),
							ivec4(13,255,215,140),
							ivec4(14,255,205,125),
							ivec4(15,255,200,110),
							ivec4(16,255,200,97),
							ivec4(17,255,195,80),
							ivec4(18,255,190,70),
							ivec4(19,77,67,194),
							ivec4(20,15,30,70),
							ivec4(21,15,30,70),
							ivec4(22,15,30,70),
							ivec4(23,15,30,70),
							ivec4(24,15,30,70));
							
	ivec4 temp = ToD[int(floor(hour))];
	ivec4 temp2 = ToD[int(floor(hour)) + 1];
	
	sunlight_color = mix(vec3(temp.yzw),vec3(temp2.yzw),(hour-float(temp.x))/float(temp2.x-temp.x))/255.0f;
	
	sunlight_color = mix(sunlight_color,vec3(0.2),rainStrength*0.5);
	
	
	////////////////////ambient color////////////////////
	////////////////////ambient color////////////////////
	////////////////////ambient color////////////////////
	ivec4 ToD2[25] = ivec4[25](ivec4(0,25,50,100), //hour,r,g,b
							ivec4(1,25,50,100),
							ivec4(2,25,50,100),
							ivec4(3,25,50,100),
							ivec4(4,25,50,100),
							ivec4(5,45,70,110),
							ivec4(6,160,170,255),
							ivec4(7,160,175,255),
							ivec4(8,160,180,260),
							ivec4(9,165,190,270),
							ivec4(10,190,205,280),
							ivec4(11,205,230,290),
							ivec4(12,220,255,300),
							ivec4(13,205,230,290),
							ivec4(14,190,205,280),
							ivec4(15,165,190,270),
							ivec4(16,150,176,260),
							ivec4(17,140,160,255),
							ivec4(18,128,150,255),
							ivec4(19,77,67,194),
							ivec4(20,25,50,100),
							ivec4(21,25,50,100),
							ivec4(22,25,50,100),
							ivec4(23,25,50,100),
							ivec4(24,25,50,100));
							
	ivec4 tempa = ToD2[int(floor(hour))];
	ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
	
	ambient_color = mix(vec3(tempa.yzw),vec3(tempa2.yzw),(hour-float(tempa.x))/float(tempa2.x-tempa.x))/255.0f;
	
	vec3 ambient_color_rain = vec3(0.2, 0.2, 0.2); //rain
	ambient_color = mix(ambient_color, ambient_color_rain, rainStrength*0.6); //rain
	
}
