#version 120

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

	////////////////////ambient color////////////////////
	////////////////////ambient color////////////////////
	////////////////////ambient color////////////////////
	const ivec4 ToD2[25] = ivec4[25](ivec4(0,10,20,45), //hour,r,g,b
							ivec4(1,10,20,45),
							ivec4(2,10,20,45),
							ivec4(3,10,20,45),
							ivec4(4,10,20,45),
							ivec4(5,60,120,180),
							ivec4(6,160,200,255),
							ivec4(7,160,205,255),
							ivec4(8,160,210,260),
							ivec4(9,165,220,270),
							ivec4(10,190,235,280),
							ivec4(11,205,250,290),
							ivec4(12,220,250,300),
							ivec4(13,205,250,290),
							ivec4(14,190,235,280),
							ivec4(15,165,220,270),
							ivec4(16,150,210,260),
							ivec4(17,140,200,255),
							ivec4(18,120,140,220),
							ivec4(19,50,55,110),
							ivec4(20,10,20,45),
							ivec4(21,10,20,45),
							ivec4(22,10,20,45),
							ivec4(23,10,20,45),
							ivec4(24,10,20,45));
							
							
void main() {

	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;
	
	ivec4 tempa = ToD2[int(floor(hour))];
	ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
	
	vec3 ambient_color = mix(vec3(tempa.yzw),vec3(tempa2.yzw),(hour-float(tempa.x))/float(tempa2.x-tempa.x))/255.0f;
	
	vec3 ambient_color_rain = vec3(0.2, 0.2, 0.2); //rain

	//ambient_color.g *= 1.2;
	ambient_color = sqrt(pow(mix(ambient_color, ambient_color_rain, rainStrength*0.75),vec3(2.0))*2.0*ambient_color); //rain
	
	

	
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
	
	gl_FragData[0].rgb = ambient_color/2.0;
	gl_FragData[0] = mix(gl_FragData[0],gl_Fog.color,1.0-fogFactor);
}