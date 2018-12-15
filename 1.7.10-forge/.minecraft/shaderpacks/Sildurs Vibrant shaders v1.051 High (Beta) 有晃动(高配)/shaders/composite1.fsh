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

	#define GODRAYS			//in this step previous godrays result is blurred
		const float exposure = 15.0;			//godrays intensity 15.0 is default
		const float density = 1.0;			
		const int NUM_SAMPLES = 6;			//increase this for better quality at the cost of performance /8 is default
		const float grnoise = 0.0;		//amount of noise /0.0 is default
		
	#define WATER_REFLECTIONS			
		#define REFLECTION_STRENGTH 1.0

#define BLOCK_REFLECTIONS	
		
/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/



//don't touch these lines if you don't know what you do!
const int maxf = 10;				//number of refinements
const float stp = 1.0;			//size of one step for raytracing algorithm
const float ref = 0.05;			//refinement multiplier
const float inc = 2.2;			//increasement factor at each step


const int Wmaxf = 4;			//number of refinements
const float Wstp = 1.0;			//size of one step for raytracing algorithm
const float Wref = 0.1;			//refinement multiplier
const float Winc = 2.4;			//increasement factor at each step

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 lightVector;
varying vec3 ambient_color;

uniform sampler2D gaux2;
uniform sampler2D depthtex2;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;


uniform sampler2D composite;
uniform sampler2D gaux4;
uniform sampler2D gaux1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D noisetex;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform int isEyeInWater;
uniform int worldTime;
uniform float far;
uniform float near;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform int fogMode;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float matflag = texture2D(gaux1,texcoord.xy).g;

vec3 fogclr = pow(mix(vec3(0.5,0.5,1.0),vec3(0.3,0.3,0.3),rainStrength)*ambient_color,vec3(2.2));
vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;

float time = float(worldTime);
float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);

float sky_lightmap = texture2D(gaux1,texcoord.xy).r;
float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(10.5+max(dot(normal,normalize(upPosition)),0.0));

vec4 color = texture2D(composite,texcoord.xy);
vec3 reflection_color = vec3(0.72,0.72,0.82);
	
float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

float luma(vec3 color) {
return dot(color.rgb,vec3(0.299, 0.587, 0.114));
}

float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

vec3 skyLightIntegral (vec3 fposition) {
vec3 sky_color = ambient_color*2.0;
sky_color = mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength);
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);
const float PI = 3.14159265359;
float Lz = 1.0;
float T = max(acos(dot(sVector,upVector)),0.0); 
float S = max(acos(dot(lightVector,upVector)),0.0);
float Y = max(acos(dot(lightVector,sVector)),0.0);
float blueDif = (1+2.0*cos(T));
float sunDif =  (1.0+2.0*max(cos(Y),0.0));
float hemisphereIntegral = PI + 2.0*(sin(T+PI/2.0)-sin(T-PI/2.0));
float sunIntegral = PI + 2.0*max(sin(Y+PI/2.0)*sin(Y+PI/2.0)*sin(Y+PI/2.0)-sin(Y-PI/2.0)*sin(Y-PI/2.0)*sin(Y-PI/2.0),0.0);
return hemisphereIntegral*sky_color*Lz + sunIntegral*sunlight*(1-rainStrength*0.9);
}

float subSurfaceScattering(vec3 pos, float N) {
return pow(max(dot(lightVector,normalize(pos)),0.0),N)*(N+1)/6.28;
}

vec3 getSkyColor(vec3 fposition) {
//sky gradient
/*----------*/
vec3 sky_color = pow(ambient_color,vec3(2.2))*2.0;
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);
sky_color = mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength);

float Lz = 1.0;
float cosT = dot(sVector,upVector);
float cosS = dot(lightVector,upVector);
float S = acos(cosS);
float cosY = dot(lightVector,sVector);
float Y = acos(cosY);
float cosT2 = abs(cosT);

float L =   pow(((0.91+10*exp(-3*Y)+0.45*cosY*cosY)*(1.0-exp(-0.32/cosT2)))/((0.91+10*exp(-3*S)+0.45*cosS*cosS)*(1.0-exp(-0.32))),1.0-rainStrength*0.8);
sky_color = mix(sky_color,pow(sunlight,vec3(2.2)),1-exp(-0.3*L*(1-rainStrength*0.8)));
sky_color = vec3(L*Lz)*sky_color;
/*----------*/


//cloud generation
/*----------*/
vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);
vec3 intersection = wVector*(12.0/wVector.y);

//float canHit = length(intersection)-length(tpos);

	vec2 wind = vec2(frameTimeCounter*(cos(frameTimeCounter/1000.0)+0.5),frameTimeCounter*(sin(frameTimeCounter/5000.0)+0.5))*0.4;
	
	vec3 wpos = tpos.xyz+cameraPosition;
	intersection.xz = intersection.xz + 2.0*cosT*intersection.xz;		//curve the cloud pattern, because sky is not 100% plane in reality
	vec2 coord = (intersection.xz+wind)/512.0;
	float noise = texture2D(noisetex,fract(coord.xy/2.0)).x;
	noise += texture2D(noisetex,fract(coord.xy)).x/2.0;
	noise += texture2D(noisetex,fract(coord.xy*2.0)).x/4.0;
	noise += texture2D(noisetex,fract(coord.xy*4.0)).x/8.0;
	noise += texture2D(noisetex,fract(coord.xy*8.0)).x/16.0;
	noise += texture2D(noisetex,fract(coord.xy*16.0)).x/32.0;
	noise += texture2D(noisetex,fract(coord.xy*32.0)).x/64.0;
	noise += texture2D(noisetex,fract(coord.xy*64.0)).x/128.0;
	noise += texture2D(noisetex,fract(coord.xy*128.0)).x/256.0;
	
	float coverageVariance = cos(length(coord)*50.0)+1.0;
	float c = max(noise-1.0-coverageVariance*0.1+rainStrength*0.18,0.0);

 
      float cloud = (1.0 - (pow(0.2-rainStrength*0.19,c)))*max(cosT,0.0);
	  float N = 12.0;
vec3 cloud_color = skyLightIntegral(sVector)/1.57 + sunlight*48.0*pow(max(cosY,0.0),N)*(N+1)/6.28 * (cloud*0.5+0.5) * (1-rainStrength);	//coloring clouds
/*----------*/
return mix(sky_color,cloud_color,cloud);  //mix up sky color and clouds
}

vec3 getFogColor(vec3 fposition) {
vec3 sky_color = pow(ambient_color,vec3(2.2));
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);
float Lz = 1.0;
float cosT = abs(dot(sVector,upVector));
float cosS = dot(lightVector,upVector);
float S = acos(cosS);
float cosY = dot(lightVector,sVector);
float Y = acos(cosY);
sky_color = mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength);
float L =  pow(sqrt(((0.91+10*exp(-3*Y)+0.45*cosY*cosY)*(1.0-exp(-0.32/cosT)))/((0.91+10*exp(-3*S)+0.45*cosS*cosS)*(1.0-exp(-0.32)))),1.0-rainStrength*0.8);
sky_color = mix(sky_color,sunlight,1-exp(-0.2*L*(1-rainStrength*0.8)));
return vec3(L*Lz)*sky_color;
}


vec3 drawSun(vec3 fposition,vec3 color,int land) {
vec3 sVector = normalize(fposition);
float sun = max(pow(clamp(dot(sVector,lightVector)+0.002,0.0,1.0),1000.0)-0.002,0.0)*land*(1-night);
vec3 sunlight = mix(sunlight,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength*0.8);
return mix(color,sunlight*MAX_COLOR_RANGE,sun);
}

vec3 calcFog(vec3 fposition, vec3 color) {
	float fog = exp(-pow(length(fposition)/256.0,4.0-(1.9*rainStrength,2.2*isEyeInWater))*499.0);
	float fogfactor =  clamp(fog,0.0,1.0);
	fogclr = getFogColor(fposition.xyz);
	return mix((fogclr+color.rgb*2.0*(1-rainStrength*0.9))/(1+2.0*(1-rainStrength*0.9)),color.rgb,fogfactor);
}
	
vec4 raytrace(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<40;i++){ //reminder light
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = abs(fragpos.z-spos.z);
if(err < pow(length(vector)*1.85,1.15)){
	
                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					color.rgb = calcFog(spos,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=ref;
				
        
}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}

vec4 raytraceWorld(vec3 fragpos, vec3 normal) {
if (rainStrength > 0.1){
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = Wstp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<15;i++){	//low
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
        if(err < pow(length(vector)*pow(length(tvector),0.11),1.1)*1.1){

                sr++;
                if(sr >= Wmaxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 3.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=Wref;    
	}
        vector *= Winc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
		}
    return color;
	} else {
  } 
}

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 
 
void main() {
	color.rgb = pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE;
	int land = int(matflag < 0.03);
	int iswater = int(matflag > 0.04 && matflag < 0.07);
	int hand  = int(matflag > 0.75 && matflag < 0.85);
	
	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
	color.rgb = drawSun(fragpos,color.rgb,land);
	
	float fresnel_pow = mix(1.0,5.0,float(iswater));
		float normalDotEye = dot(normal, normalize(fragpos));
		float fresnel = clamp(pow(1.0 + normalDotEye, fresnel_pow),0.0,1.0);
		float fmult = 0.3;
		fresnel = fresnel;
		vec4 reflection;
		
#ifdef WATER_REFLECTIONS
if (isEyeInWater > 0.9){
} else if (iswater > 0.9) {
		vec3 npos = normalize(fragpos);
		vec3 reflectedVector = reflect(normalize(fragpos), normalize(normal));
		reflectedVector = fragpos + reflectedVector * (far-length(fragpos));
		vec3 sky_color = calcFog(reflectedVector,getSkyColor(reflectedVector));
		reflection = raytrace(fragpos, normal);
		reflection.rgb = mix(sky_color, reflection.rgb, reflection.a);			//fake sky reflection, avoid empty spaces
		reflection.a = min(reflection.a,1.0);
		color.rgb = reflection.rgb *fresnel * REFLECTION_STRENGTH + (1-fresnel)*color.rgb;
		color.rgb += (color.a)*sunlight*(1.0-rainStrength)*48.0;
}
#endif

	
#ifdef BLOCK_REFLECTIONS
if (iswater > 0.9 && hand > 0.9){
} else if (iswet > 0.9 && rainStrength > 0.1){
reflection = raytraceWorld(fragpos, normal);			
		reflection.rgb = mix(reflection_color, reflection.rgb, reflection.a);
		reflection.a = min(reflection.a + 0.5,0.5);
		color.rgb = mix(color.rgb,reflection.rgb , fresnel *0.2*reflection.a*rainStrength);
} else {
}	
#endif

	vec3 colmult = mix(vec3(1.0),vec3(0.1,0.25,0.45),isEyeInWater);
	float depth_diff = clamp(pow(ld(texture2D(depthtex0, texcoord.st).r)*3.4,2.0),0.0,1.0);
	color.rgb = mix(color.rgb*colmult,vec3(0.05,0.1,0.15),depth_diff*isEyeInWater);
	
	color.rgb = calcFog(fragpos.xyz,color.rgb);

	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13500.0)/300.0,0.0,1.0) + clamp((time-22500.0)/300.0,0.0,1.0)-clamp((time-23400.0)/300.0,0.0,1.0));	//fading between sun/moon shadows

/* DRAWBUFFERS:5 */
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	
#ifdef GODRAYS
	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.25);
	if (truepos > 0.05) {
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
		deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float illuminationDecay = 1.0;
		vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));
		float gr = 0.0;
		float avgdecay = 0.0;
		float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(texcoord.y-lightPos.y);
		illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),5.0);
		float fallof = 1.0;
				
const int nSteps = 11;
const float blurScale = 0.002;
deltaTextCoord = normalize(deltaTextCoord);

int center = (nSteps-1)/2;

vec3 blur = vec3(0.0);
float tw = 0.0;

float sigma = 0.25;
float A = 1.0/sqrt(2.0*3.14159265359*sigma);


textCoord -= deltaTextCoord*center*blurScale;
		for(int i=0; i < nSteps ; i++) {
				textCoord += deltaTextCoord*blurScale;
				
				float dist = (i-float(center))/center;
				float weight = A*exp(-(dist*dist)/(2.0*sigma));
				
				
				float sample = texture2D(gdepth, textCoord).r*weight;
				tw += weight;
				gr += sample;
		}
		
		color.rgb += mix(sunlight,getFogColor(fragpos.xyz),rainStrength)*exposure*(gr/tw)*(1.0 - rainStrength*0.8)*illuminationDecay*truepos*transition_fading;
	}
#endif
	
	float visiblesun = 0.0;
	float temp;
	float nb = 0;
	
//calculate sun occlusion (only on one pixel) 
	if (texcoord.x < pw && texcoord.x < ph) {
		for (int i = 0; i < 10;i++) {
			for (int j = 0; j < 10 ;j++) {
			temp = texture2D(gaux1,lightPos + vec2(pw*(i-5.0),ph*(j-5.0))*10.0).g;
			visiblesun +=  1.0-float(temp > 0.04) ;
			nb += 1.0;
		}
	}
	visiblesun /= nb;
}

	color.rgb = clamp(pow(color.rgb/MAX_COLOR_RANGE,vec3(1.0/2.2)),0.0,1.0);
	gl_FragData[0] = vec4(color.rgb,visiblesun);
}