#version 120

/*
                            _____ _____ ___________ 
                           /  ___|_   _|  _  | ___ \
                           \ `--.  | | | | | | |_/ /
                            `--. \ | | | | | |  __/ 
                           /\__/ / | | \ \_/ / |    
                           \____/  \_/  \___/\_|    

						Before editing anything here make sure you've 
						read The agreement, which you accepted by downloading
						my shaderpack. The agreement can be found here:
			http://www.minecraftforum.net/topic/1953873-164-172-sildurs-shaders-pcmacintel/
						   
						Sildur's shaders, derived from Chocapic's shaders */
						
						
/*--------------------
//ADJUSTABLE VARIABLES//
---------------------*/

#define LENS_FLARE

//#define BLOOM								//do the "fog blur" in the same time	
	#define B_TRESH 0.4				
	#define B_RAD 20.0						//sampling circle size multiplier, don't affect performance
	#define B_INTENSITY 1.0					//basic multiplier

//#define DOF									//Enable together with one of this 3 settings below. Works together with bloom.
	//#define DOF_gaming
	//#define DOF_cinematic_camera 				
	//#define DOF_cinematic_tilt_shift


/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/


#ifdef DOF_gaming
const float focal = 0.008;
float aperture = 0.009;	
const float sizemult = 100.0;
#endif

#ifdef DOF_cinematic_tilt_shift
const float focal = 0.3;
float aperture = 0.3;	
const float sizemult = 1.0;
#endif

#ifdef DOF_cinematic_camera
const float focal = 0.05;
float aperture = focal/7.0;	
const float sizemult = 100.0;
#endif


varying vec4 texcoord;
varying vec3 sunlight;

uniform sampler2D gaux1;
vec3 aux = texture2D(gaux1, texcoord.st).rgb;

uniform sampler2D depthtex0;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform ivec2 eyeBrightness;
uniform int isEyeInWater;
uniform int worldTime;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
vec3 sunPos = sunPosition;
uniform int fogMode;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float timefract = worldTime;

//Raining
float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;
float wetx  = clamp(wetness, 0.0f, 1.0f);

//Calculate Time of Day
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

//Realistic switch between night and morning.
float TimeRealNightMorning = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 23200.0) - 23000.0) / 200.0);

// Standard depth function.
float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

#ifdef BLOOM
const vec2 offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
									vec2(-0.1717194f,0.6272162f),
									vec2(-0.4709477f,-0.01774091f),
									vec2(-0.9910634f,0.03831699f),
									vec2(-0.2101292f,0.2034733f),
									vec2(-0.7889516f,-0.5671548f),
									vec2(-0.1037751f,-0.1583221f),
									vec2(-0.5728408f,0.3416965f),
									vec2(-0.1863332f,0.5697952f),
									vec2(0.3561834f,0.007138769f),
									vec2(0.2868255f,-0.5463203f),
									vec2(-0.4640967f,-0.8804076f),
									vec2(0.1969438f,0.6236954f),
									vec2(0.6999109f,0.6357007f),
									vec2(-0.3462536f,0.8966291f),
									vec2(0.172607f,0.2832828f),
									vec2(0.4149241f,0.8816f),
									vec2(0.136898f,-0.9716249f),
									vec2(-0.6272043f,0.6721309f),
									vec2(-0.8974028f,0.4271871f),
									vec2(0.5551881f,0.324069f),
									vec2(0.9487136f,0.2605085f),
									vec2(0.7140148f,-0.312601f),
									vec2(0.0440252f,0.9363738f),
									vec2(0.620311f,-0.6673451f)
									);
#endif
	


#ifdef DOF

//hexagon pattern
const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
									vec2(  0.0000,  0.2500 ),
									vec2( -0.2165,  0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2(  0.2165, -0.1250 ),
									vec2(  0.4330,  0.2500 ),
									vec2(  0.0000,  0.5000 ),
									vec2( -0.4330,  0.2500 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.0000, -0.5000 ),
									vec2(  0.4330, -0.2500 ),
									vec2(  0.6495,  0.3750 ),
									vec2(  0.0000,  0.7500 ),
									vec2( -0.6495,  0.3750 ),
									vec2( -0.6495, -0.3750 ),
									vec2( -0.0000, -0.7500 ),
									vec2(  0.6495, -0.3750 ),
									vec2(  0.8660,  0.5000 ),
									vec2(  0.0000,  1.0000 ),
									vec2( -0.8660,  0.5000 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.0000, -1.0000 ),
									vec2(  0.8660, -0.5000 ),
									vec2(  0.2163,  0.3754 ),
									vec2( -0.2170,  0.3750 ),
									vec2( -0.4333, -0.0004 ),
									vec2( -0.2163, -0.3754 ),
									vec2(  0.2170, -0.3750 ),
									vec2(  0.4333,  0.0004 ),
									vec2(  0.4328,  0.5004 ),
									vec2( -0.2170,  0.6250 ),
									vec2( -0.6498,  0.1246 ),
									vec2( -0.4328, -0.5004 ),
									vec2(  0.2170, -0.6250 ),
									vec2(  0.6498, -0.1246 ),
									vec2(  0.6493,  0.6254 ),
									vec2( -0.2170,  0.8750 ),
									vec2( -0.8663,  0.2496 ),
									vec2( -0.6493, -0.6254 ),
									vec2(  0.2170, -0.8750 ),
									vec2(  0.8663, -0.2496 ),
									vec2(  0.2160,  0.6259 ),
									vec2( -0.4340,  0.5000 ),
									vec2( -0.6500, -0.1259 ),
									vec2( -0.2160, -0.6259 ),
									vec2(  0.4340, -0.5000 ),
									vec2(  0.6500,  0.1259 ),
									vec2(  0.4325,  0.7509 ),
									vec2( -0.4340,  0.7500 ),
									vec2( -0.8665, -0.0009 ),
									vec2( -0.4325, -0.7509 ),
									vec2(  0.4340, -0.7500 ),
									vec2(  0.8665,  0.0009 ),
									vec2(  0.2158,  0.8763 ),
									vec2( -0.6510,  0.6250 ),
									vec2( -0.8668, -0.2513 ),
									vec2( -0.2158, -0.8763 ),
									vec2(  0.6510, -0.6250 ),
									vec2(  0.8668,  0.2513 ));

#endif


float distratio(vec2 pos, vec2 pos2, float ratio) {
float xvect = pos.x*ratio-pos2.x*ratio;
float yvect = pos.y-pos2.y;
return sqrt(xvect*xvect + yvect*yvect);
}

//circle position pattern (vec2 coordinate, size)
const vec3 pattern[16] = vec3[16](	vec3(0.1,0.1,0.02),
								vec3(-0.12,0.07,0.02),
								vec3(-0.11,-0.13,0.02),
								vec3(0.1,-0.1,0.02),
								
								vec3(0.07,0.15,0.02),
								vec3(-0.08,0.17,0.02),
								vec3(-0.14,-0.07,0.02),
								vec3(0.15,-0.19,0.02),
								
								vec3(0.012,0.15,0.02),
								vec3(-0.08,0.17,0.02),
								vec3(-0.14,-0.07,0.02),
								vec3(0.02,-0.17,0.021),
								
								vec3(0.10,0.05,0.02),
								vec3(-0.13,0.09,0.02),
								vec3(-0.05,-0.1,0.02),
								vec3(0.1,0.01,0.02)
								);
								
float gen_circular_lens(vec2 center, float size) {
return 1.0-pow(min(distratio(texcoord.xy,center,aspectRatio),size)/size,3.0);
}

vec2 noisepattern(vec2 pos) {
return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
} 
void main() {
	vec2 fake_refract = vec2(sin(worldTime/15.0 + texcoord.x*100.0 + texcoord.y*50.0),cos(worldTime/15.0 + texcoord.y*100.0 + texcoord.x*50.0)) * isEyeInWater;
	vec3 color = texture2D(gaux2, texcoord.st + fake_refract * 0.005).rgb;
	float hand = float(aux.g > 0.75 && aux.g < 0.85);	


#ifdef DOF
if (hand > 0.9){
} else {	
	//Calculate pixel Circle of Confusion that will be used for bokeh depth of field
	float z = ld(texture2D(depthtex0, texcoord.st).r)*far;
	float focus = ld(texture2D(depthtex0, vec2(0.5)).r)*far;
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*10.0);		
	
	vec4 sample = vec4(0.0);
	vec3 bcolor = vec3(0.0);
	float nb = 0.0;
	vec2 bcoord = vec2(0.0);

	for ( int i = 0; i < 60; i++) {
		sample = texture2D(gaux2, texcoord.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio));
		bcolor += sample.rgb;
	}
	
	color.rgb = bcolor/60.0;
}	
#endif
	
	float plum = luma(color.rgb);

#ifdef BLOOM
const int GL_LINEAR = 9729;
const int GL_EXP = 2048;
	vec3 blur = vec3(0.0);
	float depth_diff = clamp(pow(ld(texture2D(depthtex0, texcoord.st).r)*4.0,0.8),0.0,1.0)+0.1;
	float fog = 0.0;
	fog = 1.0-clamp(exp(-ld(texture2D(depthtex0, texcoord.st).r)),0.0,1.0);

			float scale = length(vec2(pw,ph));
			vec3 csample = vec3(0.0);
				for (int i=0; i < 25; i++) {
				vec2 coords = offsets[i];
				vec3 sample = texture2D(gaux2,texcoord.xy + coords*B_RAD*scale).rgb;
				csample += max(texture2D(gaux2,texcoord.xy + coords*B_RAD*scale).rgb-plum*0.75-B_TRESH,0.0) * (length(coords)+0.6)/2.0;
				blur += sample;
			}
		//fog blurring with the distance
		color.rgb = mix(color,blur/25.0,depth_diff*isEyeInWater*0.4+fog*(1.0-isEyeInWater)*rainStrength);
		color += csample/25.0*B_INTENSITY;
#endif

color.rgb += texture2D(gaux4,texcoord.xy).rgb*sqrt(texture2D(gaux4,texcoord.xy).a);

	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;

float xdist = abs(lightPos.x-texcoord.x);
float ydist = abs(lightPos.y-texcoord.y);
float xydist = distance(lightPos.xy,texcoord.xy);
float xydistratio = distratio(lightPos.xy,texcoord.xy,aspectRatio);
float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);
float time = float(worldTime);
float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));
float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a*2.5,1.0) * (1.0-rainStrength*0.9) * fading * transition_fading;


#ifdef LENS_FLARE
float centerdist = distance(lightPos.xy,vec2(0.5))/1.412;
float sizemult = 1.0 + centerdist;
float noise = fract(sin(dot(texcoord.st ,vec2(18.9898f,28.633f))) * 4378.5453f)*0.1 + 0.9;

if (sunvisibility > 0.05) {
	float anamorphic_lens = max(pow(max(1.0 - ydist/1.412,0.1),8.0)-0.2,0.0);
		color += sunlight * vec3(0.35,0.35,1.0)*anamorphic_lens*0.62*sunvisibility;
}


if (rainStrength > 0.1) {
const float pi = 3.14159265359;
vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.25,0.25,0.25),rainStrength)*vec3(0.7,0.7,1.0);
float rainlens = 0.0;
float time = frameTimeCounter;

float gen = sin(time*pi)*0.5+0.5;
vec2 pos = noisepattern(vec2(-0.94386347*floor(time*0.5+0.25),floor(time*0.5+0.25)));
rainlens += gen_circular_lens(pos,0.04)*gen*rainStrength*1.5;

gen = cos(time*pi)*0.5+0.5;
pos = noisepattern(vec2(0.9347*floor(time*0.5+0.5),-0.2533282*floor(time*0.5+0.5)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength*1.5;

gen = cos(time*pi)*0.5+0.5;
pos = noisepattern(vec2(0.785282*floor(time*0.5+0.5),-0.285282*floor(time*0.5+0.5)));
rainlens += gen_circular_lens(pos,0.03)*gen*rainStrength*1.5;

gen = sin(time*pi)*0.5+0.5;
pos = noisepattern(vec2(-0.347*floor(time*0.5+0.25),0.6847*floor(time*0.5+0.25)));
rainlens += gen_circular_lens(pos,0.05)*max(gen*rainStrength*1.5,1.0);
color += 0.2*fogclr*rainlens*(eyeBrightness.y/255.0);

}
#endif

	color.r = (color.r*1.3)+(color.b+color.g)*(-0.1);
    color.g = (color.g*1.2)+(color.r+color.b)*(-0.1);
    color.b = (color.b*1.1)+(color.r+color.g)*(-0.1);
	color = color / (color + 2.2) * (1.0+2.2);

if (sunvisibility > 0.05) {
color *= 1.2;
} else {
color *= 1.05;
}	
	
	gl_FragColor = vec4(color,1.0);
	
}
