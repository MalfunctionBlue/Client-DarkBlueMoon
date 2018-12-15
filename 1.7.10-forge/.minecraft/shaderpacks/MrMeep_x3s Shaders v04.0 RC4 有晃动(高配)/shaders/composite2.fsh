#version 120






/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////GET MATERIAL////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

uniform sampler2D depthtex0;
uniform sampler2D composite;
uniform sampler2D gaux2;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform mat4 gbufferProjectionInverse;
uniform sampler2D gcolor;
uniform int isEyeInWater;
uniform int worldTime;
varying vec4 texcoord;

float pixeldepth = texture2D(depthtex0,texcoord.xy).x;

float matflag = texture2D(gaux1,texcoord.xy).g;
int iswater = int(matflag > 0.04 && matflag < 0.07);
	
	
	

	
	
	
	
	
		
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CODE////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {

	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;

	float distance = sqrt(fragposition.x * fragposition.x + fragposition.y * fragposition.y + fragposition.z * fragposition.z);
	
    if (isEyeInWater > 0.9) {
	vec2 fake_refract = vec2(sin(worldTime/10.0 + texcoord.x*100.0 + texcoord.y*50.0),cos(worldTime/15.0 + texcoord.y*100.0 + texcoord.x*50.0)) * isEyeInWater;
	vec3 watercolor = texture2D(gaux2, texcoord.st + fake_refract * 0.005).rgb;
	gl_FragColor = vec4(watercolor,1.0);
	
	} else {

	if (distance < 10.0 && distance > 0.1) {
	vec2 fake_refract = vec2(sin(worldTime/2.0 + texcoord.x*100.0 + texcoord.y*100.0),cos(worldTime/2.0 + texcoord.y*100.0 + texcoord.x*100.0)) * (iswater);
	vec3 watercolor = texture2D(gaux2, texcoord.st + fake_refract * 0.0015).rgb;
	gl_FragColor = vec4(watercolor,1.0);

	} else {
	
	vec2 fake_refract = vec2(sin(worldTime/2.0 + texcoord.x*100.0 + texcoord.y*100.0),cos(worldTime/2.0 + texcoord.y*100.0 + texcoord.x*100.0)) * (iswater);
	vec3 watercolor = texture2D(gaux2, texcoord.st + fake_refract * 0.0007).rgb;
	gl_FragColor = vec4(watercolor,1.0);

	}
	}
}
