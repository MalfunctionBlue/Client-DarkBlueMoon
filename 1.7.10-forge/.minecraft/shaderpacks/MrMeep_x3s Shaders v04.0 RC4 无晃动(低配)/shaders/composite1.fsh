#version 120

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

//#define GLOWING_SUN					//if you have weird sky issue try disabling this
//#define GLOW_SIZE 0.5


#define WATER_REFLECTIONS
#define REFLECTION_STRENGTH 0.8
//#define FAKE_HDR

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



//don't touch these lines if you don't know what you do!
const int maxf = 6;				//number of refinements
const float stp = 1.0;			//size of one step for raytracing algorithm
const float ref = 0.1;			//refinement multiplier
const float inc = 2.0;			//increasement factor at each step

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 fogclr;
varying vec3 lightVector;

uniform sampler2D composite;
uniform sampler2D gaux4;
uniform sampler2D gaux1;
uniform sampler2D depthtex2;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform vec3 sunPosition;
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

uniform int fogMode;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

vec4 projz = vec4(gbufferProjectionInverse[0].x,gbufferProjectionInverse[0].y,gbufferProjectionInverse[0].z,gbufferProjectionInverse[0].w);

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
    return distance(coord,vec2(0.5))*2.0;
}

float luma(vec3 color) {
return dot(color.rgb,vec3(0.299, 0.587, 0.114));
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
    for(int i=0;i<30;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
        if(err < length(vector)*pow(length(tvector),0.1)*1.75){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 1.5), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
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


//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	float matflag = texture2D(gaux1,texcoord.xy).g;
	float land = 1.0;
	float iswater = 0.0;
	float hand = 0.0;
	
	if(matflag < 0.01) 
	land = 0.0;

	if(matflag > 0.01 && matflag < 0.07) 
	iswater = 1.0;
	
	if(matflag > 0.75 && matflag < 0.85) {
	hand = 1.0;
	}

	vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.25,0.25,0.25),rainStrength)*vec3(0.85,0.85,1.0);
	
    vec3 fragpos = vec3(texcoord.st, texture2D(depthtex2, texcoord.st).r);
    fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
    vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;
    vec4 color = texture2D(composite,texcoord.xy);
	
    if (iswater > 0.9 && isEyeInWater == 0) {
		
	#ifdef WATER_REFLECTIONS
		vec4 reflection = raytrace(fragpos, normal);
		
		float normalDotEye = dot(normal, normalize(fragpos));
		float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
		
		reflection.rgb = mix(fogclr, reflection.rgb, reflection.a);			//fake sky reflection, avoid empty spaces
		color.rgb += reflection.rgb * fresnel * (1.0-isEyeInWater) * REFLECTION_STRENGTH;
		//color.rgb += (1.0+fresnel)*spec*sunlight*(1.0-isEyeInWater)*8.0;
	#endif
	
    }
	const int GL_LINEAR = 9729;
const int GL_EXP = 2048;
	
		vec3 colmult = mix(vec3(1.0),vec3(0.1,0.25,0.45),isEyeInWater);
		float depth_diff = clamp(pow(ld(texture2D(depthtex2, texcoord.st).r)*3.4,2.0),0.0,1.0);
		color.rgb = mix(color.rgb*colmult,vec3(0.02,0.06,0.1),depth_diff*isEyeInWater);
		
		if (fogMode == 0 && hand < 0.9) {
		float fog = clamp(exp(-ld(texture2D(depthtex2, texcoord.st).r)*far/192.0*(1.0+rainStrength)/1.4)+0.25*(1.0-rainStrength),0.0,1.0);
		//inject sun color into the fog
		float volumetric_cone = max(dot(normalize(fragpos),lightVector),0.0);
		fogclr += sunlight*pow(volumetric_cone,5.0)*1.5*(1.0-rainStrength*0.9);
		color.rgb = mix(color.rgb,fogclr,1.0-fog);
		}
		
		
/* DRAWBUFFERS:5 */
	
	float lum = 0.0;
	
#ifdef FAKE_HDR
	float temp;
	float nb = 0;
	vec2 coord;
	//calculate average light intensity (only on one pixel) 
	if (texcoord.x > 1.0-pw && texcoord.x > 1.0-ph) {
		for (int i = 0; i < 31;i++) {
			for (int j = 0; j < 31 ;j++) {
				coord = vec2(0.5)+vec2((i-16.0f)/32.0,(j-16.0f)/32.0);
				lum += luma(texture2D(composite,coord).rgb)*pow(1.0-distance(coord,vec2(0.5))/sqrt(2.0),15.0);
				nb += pow(1.0-distance(coord,vec2(0.5))/sqrt(2.0),15.0);
			}
		}
		lum /= nb;
	}		
#endif
	
	//draw rain
	color.rgb += texture2D(gaux4,texcoord.xy).rgb*texture2D(gaux4,texcoord.xy).a;
	
	
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;
	#ifdef GLOWING_SUN
	//sun glow in the sky

	
	float sunmask = 1.0 - rainStrength*0.75;		//keep a subtle sun glow when raining
	
	float sun_dist = sqrt(pow(texcoord.x*aspectRatio-lightPos.x*aspectRatio,2.0) + pow(texcoord.y-lightPos.y,2.0));
	float sunglow = pow(1.0-clamp(sun_dist,0.0,GLOW_SIZE)/GLOW_SIZE,2.0);
	color.rgb += sunglow*sunlight*(1.0-land)*sunmask*0.7;
	#endif
	
float visiblesun = 0.0;
float temp;
int nb = 0;

			
//calculate sun occlusion (only on one pixel) 
if (texcoord.x < pw && texcoord.x < ph) {
	for (int i = 0; i < 16;i++) {
		for (int j = 0; j < 16 ;j++) {
		temp = texture2D(gaux1,lightPos + vec2(pw*(i-8.0)*7.0,ph*(j-8.0)*7.0)).g;
		if (temp > 0.04) visiblesun += 0.0;
		else visiblesun += 1.0;
		nb += 1;
		}
	}
	visiblesun /= nb;

}

		
	gl_FragData[0] = vec4(color.rgb,visiblesun);
	
}
