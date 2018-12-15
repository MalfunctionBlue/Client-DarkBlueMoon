#version 120


/* DRAWBUFFERS:024 */


#define MIX_TEX	0.5		
vec4 watercolor = vec4(0.1,0.22,0.28,0.85);


const int MAX_OCCLUSION_POINTS = 20;
const float MAX_OCCLUSION_DISTANCE = 100.0;
const float bump_distance = 64.0;				//Bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float pom_distance = 32.0;				//POM render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 0.1;
const float PI = 3.1415927;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec3 wpos;
varying float iswater;

uniform sampler2D texture;
uniform sampler2D noisetex;
uniform int worldTime;
uniform float far;
uniform float rainStrength;
uniform float frameTimeCounter;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

float waterH(vec2 waterpos) {

	vec2 coord= waterpos/128.0;
	float noise = texture2D(noisetex,fract(coord.xy/2.0)).x;
	noise += texture2D(noisetex,fract(coord.xy)).x/2.0;
	noise += texture2D(noisetex,fract(coord.xy*2.0)).x/4.0;
	noise += texture2D(noisetex,fract(coord.xy*4.0)).x/8.0;
	
	return 	0.05 * sin(2 * PI * (frameTimeCounter + waterpos.x  + waterpos.y / 2.0 + noise*2.0))
	+ 0.05 * sin(2 * PI * (frameTimeCounter*1.2 + waterpos.x / 2.0 + waterpos.y + noise*2.0));
	//return noise;
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {	
	
	vec4 tex = vec4((watercolor*mix(vec4(1.0),texture2D(texture, texcoord.xy),MIX_TEX)*color).rgb,watercolor.a);
	if (iswater < 0.9)  tex = texture2D(texture, texcoord.xy)*color;
	
	vec3 waterpos = wpos.xyz;
	waterpos.x += (waterpos.z-frameTimeCounter)*0.1;
	waterpos.z += (waterpos.x+frameTimeCounter*0.45)*3.0;
	
	float deltaPos = 0.1;
	float h0 = waterH(waterpos.xz);
	float h1 = waterH(waterpos.xz + vec2(deltaPos,0.0));
	float h2 = waterH(waterpos.xz + vec2(-deltaPos,0.0));
	float h3 = waterH(waterpos.xz + vec2(0.0,deltaPos));
	float h4 = waterH(waterpos.xz + vec2(0.0,-deltaPos));
	
	float xDelta = (h1-h0)+(h0-h2);
	float yDelta = (h3-h0)+(h0-h4);
	float zDelta = h0-(h1+h2+h3+h4)/4.0;
	
	vec3 newnormal = normalize(vec3(xDelta,yDelta,1.0-pow(abs(xDelta+yDelta),2.0)));
	
	vec4 frag2;
		frag2 = vec4((normal) * 0.5f + 0.5f, 1.0f);			
	float NdotE = sqrt(abs(dot(normal,normalize(position.xyz))));
	if (iswater > 0.9) {
		vec3 bump = newnormal;
			bump = bump;
			
		
		float bumpmult = 0.22*NdotE;	
		
		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);
		
		frag2 = vec4(normalize(bump * tbnMatrix) * 0.5 + 0.5, 1.0);
	}
	
	gl_FragData[0] = tex;
	
	gl_FragData[1] = frag2;	
	
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
}