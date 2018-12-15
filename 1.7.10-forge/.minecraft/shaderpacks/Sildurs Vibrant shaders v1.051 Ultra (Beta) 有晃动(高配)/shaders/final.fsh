#version 120
#define MAX_COLOR_RANGE 48.0

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

#define BLOOM							//make certain blocks like glowstone kinda glowing

#define DOF							//This is Hexagonal Bokeh DoF enable with one of the settings below
	#define DISTANT_BLUR				//Enable together with DOF and DOF_gaming if you want	
	#define DOF_gaming
	//#define DOF_cinematic_camera 				
	//#define DOF_cinematic_tilt_shift


/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/

#ifdef DOF_gaming
	const float focal = 0.024;
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
varying vec3 ambient_color;

uniform sampler2D gaux1;
vec3 aux = texture2D(gaux1, texcoord.st).rgb;

uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D gcolor;
uniform sampler2D composite;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
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
uniform int fogMode;
vec3 sunPos = sunPosition;
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


float A = 0.15;
float B = 0.2;
float C = 0.1;
float D = 0.2;
float E = 0.02;
float F = 0.3;
float W = MAX_COLOR_RANGE;

vec3 Uncharted2Tonemap(vec3 x) {
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float distratio(vec2 pos, vec2 pos2, float ratio) {
	float xvect = pos.x*ratio-pos2.x*ratio;
	float yvect = pos.y-pos2.y;
	return sqrt(xvect*xvect + yvect*yvect);
}

float gen_circular_lens(vec2 center, float size) {
	return 1.0-pow(min(distratio(texcoord.xy,center,aspectRatio),size)/size,3.0);
}

vec2 noisepattern(vec2 pos) {
	return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
}
float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 
 
void main() {

		const float pi = 3.14159265359;
		vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.25,0.25,0.25),rainStrength)*vec3(0.7,0.7,1.0);
		float rainlens = 0.0;
		float hand  = float(aux.g > 0.75 && aux.g < 0.85);
		float glowingBlocks = float(aux.g > 0.56 && aux.g < 0.58);
		float iswater = float(aux.g > 0.04 && aux.g < 0.07);		
		
#ifdef LENS_FLARE		
		const float lifetime = 3.0;		//water drop lifetime in seconds
		float ftime = frameTimeCounter*2.0/lifetime;  
		float gen = 1.0-fract((ftime+0.5)*0.5);
		vec2 pos = (noisepattern(vec2(-0.94386347*floor(ftime*0.5+0.25),floor(ftime*0.5+0.25)))-0.5)*0.85+0.5;
		rainlens += gen_circular_lens(pos,0.04)*gen*rainStrength;

		gen = 1.0-fract((ftime+1.0)*0.5);
		pos = (noisepattern(vec2(0.9347*floor(ftime*0.5+0.5),-0.2533282*floor(ftime*0.5+0.5)))-0.5)*0.85+0.5;
		rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;

		gen = 1.0-fract((ftime+1.5)*0.5);
		pos = (noisepattern(vec2(0.785282*floor(ftime*0.5+0.75),-0.285282*floor(ftime*0.5+0.75)))-0.5)*0.85+0.5;
		rainlens += gen_circular_lens(pos,0.03)*gen*rainStrength;

		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.347*floor(ftime*0.5),0.6847*floor(ftime*0.5)))-0.5)*0.85+0.5;
		rainlens += gen_circular_lens(pos,0.05)*gen*rainStrength;
	
		rainlens *= clamp((eyeBrightness.y-220)/15.0,0.0,1.0);
#endif	
	
	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0));
	vec2 newTC = texcoord.st + fake_refract * 0.01 * (rainlens);
	vec3 color = pow(texture2D(gaux2, newTC).rgb,vec3(2.2))*MAX_COLOR_RANGE;
	float fog = 1-(exp(-pow(ld(texture2D(depthtex0, newTC.st).r)/256.0*far,4.0-(2.7*rainStrength))*4.0));

	
#ifdef DOF
	//Calculate pixel Circle of Confusion that will be used for bokeh depth of field
	float z = ld(texture2D(depthtex0, newTC.st).r)*far/1.4;
	float focus = ld(texture2D(depthtex0, vec2(0.5)).r)*far/1.4;
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*20.0);
	#ifdef DISTANT_BLUR
	pcoc = min(fog*pw*20.0,pw*20.0);
	#endif
	vec4 sample = vec4(0.0);
	vec3 bcolor = color/MAX_COLOR_RANGE;
	float nb = 0.0;
	vec2 bcoord = vec2(0.0);
if (hand > 0.9){
} else if (pcoc > pw*1.5) {
	
		for ( int i = 0; i < 60; i++) {
			bcolor += pow(texture2D(gaux2, newTC.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
			
		}
		color.rgb = bcolor/61.0*MAX_COLOR_RANGE;
	}
#endif


#ifdef BLOOM
const float rMult = 0.002;
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
blur += pow(texture2D(composite,texcoord.xy + rMult*vec2(1.0,aspectRatio)*vec2(0.0,i-center)).rgb,vec3(2.2))*weight;
tw += weight;
}
blur /= tw;
//blur *= 0.2;
#endif

if (hand > 0.1){
} else if (1.0 > 0.5){
	vec4 rain = pow(texture2D(gaux4,newTC.xy),vec4(2.2,2.2,2.2,0.4))*vec4(vec3(length(ambient_color))*5.0,1.0);
	color.rgb = ((rain.rgb*rain.a + color) - (rain.rgb * rain.a * color));
	//color.rgb = mix(rain.rgb,color.rgb,1-rain.a);
}	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;
		
vec3 lightVector;
if (worldTime < 12700 || worldTime > 23250) {
	lightVector = normalize(sunPosition);
} else {
	lightVector = normalize(moonPosition);
}
	
#ifdef LENS_FLARE
	float xdist = abs(lightPos.x-newTC.x);
	float ydist = abs(lightPos.y-newTC.y);
	
	float xydist = distance(lightPos.xy,newTC.xy);
	float xydistratio = distratio(lightPos.xy,newTC.xy,aspectRatio);
	
	float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
	float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);
	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));
	float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a,1.0) * (1.0-rainStrength*0.9) * fading * transition_fading;
	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.25);
	//float anamorphic_lens = clamp( 0.75-(pow(ydist,0.1)) - pow(xdist*2.0,2.0),0.0,1.0)*5.0;
	float centerdist = distance(lightPos.xy,vec2(0.5))/1.412;
	float sizemult = 1.0 + centerdist;

	float circles_lens = 0.0;
	
if (sunvisibility > 0.05) {
float lens_balance = 1.0f;
float anamorphic_lens = max(pow(max(1.0 - ydist/1.412,0.1),12.0)-0.2,0.0);
	color += sunlight * vec3(0.35,0.35,1.0*lens_balance)*anamorphic_lens*1.425*sunvisibility;
}
	
	//rain drops on screen
		color += fogclr*rainlens*vec3(0.25,0.3,0.4)*length(ambient_color);
#endif

#ifdef BLOOM
#ifndef LENS_FLARE
	float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
	float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);
	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));
	float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a,1.0) * (1.0-rainStrength*0.9) * fading * transition_fading;
#endif	
if (sunvisibility > 0.05){
} else if (iswater > 0.9){
} else if (1.0 > 0.5){
color.rgb = mix(color,blur*MAX_COLOR_RANGE,(fog)*(rainStrength));
blur *= pow(luma(blur),1.2)*5.0;
color += blur*MAX_COLOR_RANGE;
color = ((blur + color/MAX_COLOR_RANGE) - (blur * color/MAX_COLOR_RANGE))*MAX_COLOR_RANGE;
}
#endif	

	vec3 curr = Uncharted2Tonemap(color);
	vec3 whiteScale = 1.0f/Uncharted2Tonemap(vec3(W));
	
	color = curr*whiteScale; 
	color = (((color - color.rgb )*1.04)+color.rgb) ;
	color /= 1.04;

	color = pow(color,vec3(1.0/1.85));

	gl_FragColor = vec4(color,1.0);
}
