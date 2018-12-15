#version 120

/*
Chocapic13' shaders, derived from SonicEther v10 rc6
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//to increase shadow draw distance, edit shadowDistance and SHADOWHPL below. Both should be equal. Needs decimal point.
//disabling is done by adding "//" to the beginning of a line.

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

//----------Shadows----------//
const int 		shadowMapResolution 	= 1048;
const float 	shadowDistance 			= 80.0f;


	#define SHADOW_DARKNESS 0.5	//shadow darkness levels, lower values mean darker shadows, see .vsh for colors
	//#define VARIABLE_PENUMBRA_SHADOWS
	#define SHADOW_FILTER						//enable shadow anti-aliasing (slower)
//----------End of Shadows----------//

//----------Lighting----------//
	#define SUNLIGHTAMOUNT 0.9		//change sunlight strength , see .vsh for colors.
//Torch Color//
	vec3 torchcolor = vec3(1.2,0.5,0.2);		//RGB - Red, Green, Blue
	#define TORCH_POWER 4.23
	#define TORCH_INTENSITY 1.7
//----------End of Lighting----------//

//----------Visual----------//
	//#define SSAO
		#define SSAO_HQ					//hq is similar to nvidia's hbao
	//SSAO HQ constants
	const int nbdir = 5;
	const float ssaorad = 1.0;
	const float sampledir = 5;
	const float ssao_jitter = 4.0;
	//#define CELSHADING
		#define BORDER 1.0
	const float	ambientOcclusionLevel = 0.8f;		//level of Minecraft smooth lighting, 1.0f is default
	const float	sunPathRotation	= -35.0f;		//0.0f is default minecraft sun/moon inclination
//----------End of Visual----------//

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



#define SHADOW_MAP_BIAS 0.6
#define SPECMULT 0.0
#define BUMPMAPPWR 1.0			//attenuate diffuse light function as following :  diffuse^BUMPMAPPWR

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 lightVector;
varying vec3 sunlight_color;
varying vec3 ambient_color;
varying vec3 skycolor;
varying vec3 sunlight;

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D shadow;
uniform sampler2D gaux1;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;

float cdist(vec2 coord){
    return distance(coord,vec2(0.5))*2.0;
}

vec3 convertScreenSpaceToWorldSpace(vec2 co, float depth) {
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(co, depth) * 2.0 - 1.0, 1.0);
    fragposition /= fragposition.w;
    return fragposition.xyz;
}

vec3 convertCameraSpaceToScreenSpace(vec3 cameraSpace) {
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
    return screenSpace;
}

float edepth(vec2 coord) {
	return texture2D(depthtex0,coord).z;
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec2 texel = vec2(1.0/viewWidth,1.0/viewHeight);
vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 sunPos = sunPosition;
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;


float pixeldepth = texture2D(depthtex0,texcoord.xy).x;
float totalspec = aux.r*SPECMULT;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float shadowexit = 0.0;

//Lightmaps
float torch_lightmap = pow(aux.b,TORCH_POWER)*TORCH_INTENSITY;

//poisson distribution for shadow sampling		
vec2 circle_offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
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

float ctorspec(vec3 ppos, vec3 lvector, vec3 normal) {
    //half vector
	vec3 pos = -normalize(ppos);
    vec3 cHalf = normalize(lvector + pos);
	
    // beckman's distribution function D
    float normalDotHalf = dot(normal, cHalf);
    float normalDotHalf2 = normalDotHalf * normalDotHalf;

    float roughness2 = 0.1;
    float exponent = -(1.0 - normalDotHalf2) / (normalDotHalf2 * roughness2);
    float e = 2.71828182846;
    float D = pow(e, exponent) / (roughness2 * normalDotHalf2 * normalDotHalf2);
	
    // fresnel term F
	float normalDotEye = dot(normal, pos);
    float F = pow(1.0 - normalDotEye, 5.0);

    // self shadowing term G
    float normalDotLight = dot(normal, lvector);
    float X = 2.0 * normalDotHalf / dot(pos, cHalf);
    float G = min(1.0, min(X * normalDotLight, X * normalDotEye));
    float pi = 3.1415927;
    float CookTorrance = (D*F*G)/(pi*normalDotEye);
	
    return max(CookTorrance/pi,0.0);
}

float diffuseorennayar(vec3 pos, vec3 lvector, vec3 normal, float spec, float roughness) {
	
    vec3 v=normalize(pos);
	vec3 l=normalize(lvector);
	vec3 n=normalize(normal);

	float vdotn=dot(v,n);
	float ldotn=dot(l,n);
	float cos_theta_r=vdotn; 
	float cos_theta_i=ldotn; 
	float cos_phi_diff=dot(normalize(v-n*vdotn),normalize(l-n*ldotn));
	float cos_alpha=min(cos_theta_i,cos_theta_r); // alpha=max(theta_i,theta_r);
	float cos_beta=max(cos_theta_i,cos_theta_r); // beta=min(theta_i,theta_r)

	float r2=roughness*roughness;
	float a=1.0-0.5*r2/(r2+0.33);
	float b_term;
	
	if(cos_phi_diff>=0.0) {
		float b=0.45*r2/(r2+0.09);
		//b_term=b*sqrt((1.0-cos_alpha*cos_alpha)*(1.0-cos_beta*cos_beta))/cos_beta*cos_phi_diff;
		b_term = b*sin(cos_alpha)*tan(cos_beta)*cos_phi_diff;
	}
	else b_term=0.0;

	return clamp(cos_theta_i*(a+b_term*spec),0.0,1.0);
}

#ifdef CELSHADING
vec3 celshade(vec3 clrr) {
	//edge detect
	float d = edepth(texcoord.xy);
	float dtresh = 1/(far-near)/5000.0;	
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	sa.x = edepth(texcoord.xy + vec2(-pw,-ph)*BORDER);
	sa.y = edepth(texcoord.xy + vec2(pw,-ph)*BORDER);
	sa.z = edepth(texcoord.xy + vec2(-pw,0.0)*BORDER);
	sa.w = edepth(texcoord.xy + vec2(0.0,ph)*BORDER);
	
	//opposite side samples
	sb.x = edepth(texcoord.xy + vec2(pw,ph)*BORDER);
	sb.y = edepth(texcoord.xy + vec2(-pw,ph)*BORDER);
	sb.z = edepth(texcoord.xy + vec2(pw,0.0)*BORDER);
	sb.w = edepth(texcoord.xy + vec2(0.0,-ph)*BORDER);
	
	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
	dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));
	
	float e = clamp(dot(dd,vec4(0.5f,0.5f,0.5f,0.5f)),0.0,1.0);
	return clrr*e;
}
#endif

float getnoise(vec3 pos) {
return abs(fract(sin(dot(pos ,vec3(18.9898f,28.633f,35.053))) * 4378.5453f));

}

float interpolate(vec3 truepos,float center,vec3 poscenter,float value2,vec3 pos2,float value3,vec3 pos3,float value4,vec3 pos4,float value5,vec3 pos5) {
/*
float mix1 = mix(center,value2,1.0-length(truepos-pos2));
float mix2 = mix(mix1,value3,1.0-length(truepos-pos3));
float mix3 = mix(mix2,value4,1.0-length(truepos-pos4));
return mix(mix3,value5,1.0-length(truepos-pos5));
*/
return center*(1.0-distance(truepos,poscenter))+value2*(1.0-distance(truepos,pos2))+value3*(1.0-distance(truepos,pos3))+value4*(1.0-distance(truepos,pos4))+value5*(1.0-distance(truepos,pos5));
}
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {

	//unpack the specifical surfaces buffer
	float land = 0.0;
	float iswater = 0.0;
	float translucent = 0.0;
	float rainmask = 0.0;
	float hand = 0.0;
	float shadowexit = 0.0;
	
	if(aux.g > 0.1 && aux.g < 0.3){
		shadowexit = 1.0;
		land = 1.0;
	}

	if(aux.g < 0.01) {
		shadowexit = 1.0;
	}

	if(aux.g > 0.01 && aux.g < 0.07) {
		iswater = 1.0;
		land = 1.0;
	}

	if(aux.g > 0.3 && aux.g < 0.5) {
		land = 1.0;
		translucent = 1.0;
	}

	if(aux.g > 0.9) {
		land = 1.0;
	}

	if(aux.g > 0.75 && aux.g < 0.85) {
		land = 1.0;
		hand = 1.0;
	}
	
	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;

	float dist = length(fragposition.xyz);
	float shading = 1.0f;
	float shadingsharp = 0.0f;

	
	vec4 worldposition = vec4(0.0);
	vec4 worldpositionraw = vec4(0.0);
	
	worldposition = gbufferModelViewInverse * fragposition;	
	
	float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
	float yDistanceSquared  = worldposition.y * worldposition.y;
	
	worldpositionraw = worldposition;
	
	worldposition = shadowModelView * worldposition;
	float comparedepth = -worldposition.z;
	worldposition = shadowProjection * worldposition;
	worldposition /= worldposition.w;
	
	float distb = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
	float distortFactor = (1.0f - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
	worldposition.xy *= 1.0f / distortFactor;
	worldposition = worldposition * 0.5f + 0.5f;
	int vpsize = 0;
	float diffthresh = 1.0*distortFactor+iswater+translucent;
	float isshadow = 0.0;
	float ssample;

	float distof = clamp(1.0-dist/shadowDistance,0.0,1.0);
	float distof2 = clamp(1.0-dist/(shadowDistance*0.75),0.0,1.0);
	float shadow_fade = clamp(distof*12.0,0.0,1.0);
	float sss_fade = pow(distof2,0.2);
	float step = 1.0/shadowMapResolution;
	
	if (iswater + isEyeInWater > 0.9) {
	
	} else {
	
		if (dist < shadowDistance) {
			
			
			if (shadowexit > 0.1) {
				shading = 1.0;
			}
			
			else {
			#ifdef SHADOW_FILTER
				for(int i = 0; i < 25; i++){
					shadingsharp += (clamp(comparedepth - (0.05 + (texture2D(shadow, worldposition.st + circle_offsets[i]*step).z) * (256.0 - 0.05)), 0.0, diffthresh)/(diffthresh));
				}
				shadingsharp /= 25.0;
				shading = 1.0-shadingsharp;
				isshadow = 1.0;
			#endif
			
			#ifndef SHADOW_FILTER
				shading = 1.0-(clamp(comparedepth - (0.05 + (texture2D(shadow, worldposition.st).z) * (256.0 - 0.05)), 0.0, diffthresh)/(diffthresh));
			#endif
			}
			
		}
		
	}
	
	float ao = 1.0;
	
#ifdef SSAO
	
	if (land > 0.9 && iswater < 0.9 && hand < 0.9) {
	
	#ifdef SSAO_HQ
	
		vec3 norm = texture2D(gnormal,texcoord.xy).rgb*2.0-1.0;
		vec3 projpos = convertScreenSpaceToWorldSpace(texcoord.xy,pixeldepth); 
		
		float progress = 0.0;
		ao = 0.0;
		
		float projrad = clamp(distance(convertCameraSpaceToScreenSpace(projpos + vec3(ssaorad,ssaorad,ssaorad)).xy,texcoord.xy),7.5*pw,60.0*pw);
		
		for (int i = 1; i < nbdir; i++) {
			for (int j = 1; j < sampledir; j++) {
				vec2 samplecoord = vec2(cos(progress),sin(progress))*(j/sampledir)*projrad + texcoord.xy;
				float sample = texture2D(depthtex0,samplecoord).x;
				vec3 sprojpos = convertScreenSpaceToWorldSpace(samplecoord,sample);
				float angle = min(1.0-dot(norm,normalize(sprojpos-projpos)),1.0);
				float dist = min(abs(ld(sample)-ld(pixeldepth)),0.015)/0.015;
				float temp = min(dist+angle,1.0);
				ao += pow(temp,1.2);
				progress += (1.0-temp)/nbdir*3.14;
			}
			progress = i*1.256;
		}
		
		ao /= (nbdir-1)*(sampledir-1);
		
	#endif
	
	}
	
#endif
	
	float wave = 0.0;
	
	if (iswater > 0.9) {
		/*
		wave = callwaves(worldposition.xyz*1.2)*2.0-1.0;
		
		float angle = dot(normalize(fragposition.xyz),normal);
		wave = wave*(abs(angle));
		*/
	}
	
	float sss_transparency = mix(0.0,0.75,translucent);		//subsurface scattering amount
	float sunlight_direct = 1.0;
	float direct = 1.0;
	float sss = 0.0;
	vec3 npos = normalize(fragposition.xyz);
	float NdotL = 1.0;
	
	if (land > 0.9) {
		NdotL = dot(normal, lightVector);
		direct = NdotL;
		
		sunlight_direct = max(direct,0.0);
		sunlight_direct = mix(sunlight_direct,0.75,translucent);
	
		sss += pow(max(dot(npos, lightVector),0.0),20.0)*sss_transparency*clamp(-NdotL,0.0,1.0)*translucent*4.0;

	
	}
	
	sss = mix(0.0,sss,min(sss_fade+0.5,1.0));
	shading = clamp(shading,0.0,1.0);
 

	vec3 color = texture2D(gcolor, texcoord.st).rgb;

	float spec =  ctorspec(fragposition.xyz,lightVector,normalize(normal)) * shading * iswater * (1.0-isEyeInWater);
	
	//Apply different lightmaps to image
	if (land > 0.9 && isEyeInWater < 0.1) {
		float time = float(worldTime);
		float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));	
		float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);
		vec3 Sunlight_lightmap = sunlight_color*mix(1.0-rainStrength*0.9,shading*(1.0-rainStrength*0.9),shadow_fade)*SUNLIGHTAMOUNT *sunlight_direct*transition_fading ;
		
		
			/*
		float half_lambert = 1.0-sqrt(NdotL*0.5+0.5);
		float NdotUp = (dot(normal,normalize(upPosition))*0.5+0.5);
		vec3 amb = ambient_color;	
		vec3 reflected = sunlight_color*(half_lambert+(1.0-NdotUp))*0.25;
		*/
		
		float sky_inc = sqrt(direct*0.5+0.5);
		vec3 amb = (sky_inc*ambient_color+(1.0-sky_inc)*(sunlight_color+ambient_color*2.5)*vec3(0.2,0.23,0.2));
		
		vec3 Torchlight_lightmap = torch_lightmap *  torchcolor * max(night,0.7) ;
		
		vec3 color_sunlight = Sunlight_lightmap;
		vec3 color_torchlight = Torchlight_lightmap;
		
		//Add all light elements together
		color = 0.5*spec*sunlight_color*(1.0-rainStrength)*(1.0-night*0.8) +((amb)*SHADOW_DARKNESS + color_sunlight + color_torchlight  +  sss * sunlight_color * shading *(1.0-rainStrength*0.9)*transition_fading)*color;

	}
	
	else if (isEyeInWater < 0.1){
		color = mix(color,(gl_Fog.color.rgb+vec3(0.25,0.25,0.25))/2.0,rainStrength)*0.8;
	}

/* DRAWBUFFERS:3 */

//testing stuff (don't work at all)
/*
vec3 cloud = vec3(1.0);
vec3 position = worldpositionraw.xyz + cameraPosition.xyz;
vec3 fragst = floor(position+0.25);
float noise = getnoise(fragst);
float noise1 = getnoise(fragst+vec3(1.0,0.0,0.0));
float noise2 = getnoise(fragst+vec3(-1.0,0.0,0.0));
float noise3 = getnoise(fragst+vec3(0.0,1.0,0.0));
float noise4 = getnoise(fragst+vec3(0.0,1.0,0.0));

float pattern = interpolate(position-0.25,noise,fragst,noise1,fragst+vec3(1.0,0.0,0.0),noise2,fragst+vec3(-1.0,0.0,0.0),noise3,fragst+vec3(0.0,1.0,0.0),noise4,fragst+vec3(0.0,1.0,0.0));

color.rgb = vec3(pattern);
*/
#ifdef CELSHADING
	if (land > 0.9 && iswater < 0.9) color = celshade(color);
#endif
	color = clamp(color,0.0,1.0);
	gl_FragData[0] = vec4(color, 1.0);
	
}
