#version 120

#define WAVING_LEAVES
#define WAVING_VINES
#define WAVING_GRASS
#define WAVING_WHEAT
#define WAVING_FLOWERS
#define WAVING_FIRE
#define WAVING_LAVA
#define WAVING_LILYPAD
#define WAVING_SAPLINGS
#define WAVING_BROWN_MUSHROOM
#define WAVING_RED_MUSHROOM
#define WAVING_POTATOES
#define WAVING_CARROTS
#define WAVING_SUGAR_CANES

#define ENTITY_LEAVES        18.0
#define ENTITY_VINES        106.0
#define ENTITY_TALLGRASS     31.0
#define ENTITY_DANDELION     37.0
#define ENTITY_ROSE          38.0
#define ENTITY_WHEAT         59.0
#define ENTITY_LILYPAD      111.0
#define ENTITY_FIRE          51.0
#define ENTITY_LAVAFLOWING   10.0
#define ENTITY_LAVASTILL     11.0
#define ENTITY_SAPLINGS      06.0
#define ENTITY_BROWN_MUSHROOM 39.0
#define ENTITY_RED_MUSHROOM  40.0
#define ENTITY_POTATOES      142.0
#define ENTITY_CARROTS       141.0
#define ENTITY_SUGAR_CANES   83.0
uniform float frameTimeCounter;

varying vec4 color;

varying vec2 texcoord;
varying vec2 lmcoord;

attribute vec4 mc_Entity;

uniform int worldTime;
uniform float rainStrength;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
varying vec3 normal;

varying float translucent;

const float PI = 3.141592653589793;
float pi2wt = PI*2*(frameTimeCounter*24);
vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5)
{
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0);
    d1 = sin(pi2wt*f1);
    d2 = sin(pi2wt*f2);
    ret.x = sin(pi2wt*f3 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    ret.z = sin(pi2wt*f4 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
	ret.y = sin(pi2wt*f5 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2)
{
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
	vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
    return move1+move2;
}

vec3 calcWaterMove(in vec3 pos)
{
	float fy = fract(pos.y + 0.001);
	if (fy > 0.002)
	{
		float wave = 0.05 * sin(2 * PI * (worldTime / 86.0 + pos.x /  7.0 + pos.z / 13.0))
				   + 0.05 * sin(2 * PI * (worldTime / 60.0 + pos.x / 11.0 + pos.z /  5.0));
		return vec3(0, clamp(wave, -fy, 1.0-fy), 0);
	}
	else
	{
		return vec3(0);
	}
}

void main() {
	texcoord = (gl_MultiTexCoord0).xy;
	
	translucent = 0.0f;

	bool istopv = gl_MultiTexCoord0.t < gl_MultiTexCoord3.t;

	/* un-rotate */
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	
	#ifdef WAVING_LEAVES
	if ( mc_Entity.x == ENTITY_LEAVES )
			position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001, vec3(0.1,0.2,0.1), vec3(0.1,0.0,0.2));
	#endif
	#ifdef WAVING_VINES
	if ( mc_Entity.x == ENTITY_VINES )
			position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001, vec3(0.1,0.2,0.1), vec3(0.1,0.0,0.2));
	#endif
	#ifdef WAVING_GRASS
	if ( mc_Entity.x == ENTITY_TALLGRASS && istopv )
			position.xyz += calcMove(worldpos.xyz, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, vec3(1.7,1.4,1.9), vec3(1.8,1.3,1.6));
	#endif
	#ifdef WAVING_FLOWERS
	if ((mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE) && istopv )
			position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0000, 0.0001, 0.0000, 0.0001, 0.0001, vec3(1.8,1.5,2.0), vec3(1.8,1.3,1.6));
	#endif
	#ifdef WAVING_WHEAT
	if ( mc_Entity.x == ENTITY_WHEAT && istopv )
			position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0000, 0.0002, 0.0000, 0.0001, 0.0000, vec3(1.8,1.0,1.8), vec3(1.4,1.0,1.4));
	#endif
	#ifdef WAVING_FIRE
	if ( mc_Entity.x == ENTITY_FIRE && istopv )
			position.xyz += calcMove(worldpos.xyz, 0.0105, 0.0096, 0.0087, 0.0063, 0.0097, 0.0156, vec3(1.2,0.4,1.2), vec3(0.8,0.8,0.8));
	#endif
	#ifdef WAVING_LAVA
	if ( mc_Entity.x == ENTITY_LAVAFLOWING || mc_Entity.x == ENTITY_LAVASTILL )
			position.xyz += calcWaterMove(worldpos.xyz) * 0.25;
	#endif
	#ifdef WAVING_LILYPAD
	if ( mc_Entity.x == ENTITY_LILYPAD )
			position.xyz += calcWaterMove(worldpos.xyz);
	#endif
	#ifdef WAVING_SAPLINGS
	if ( mc_Entity.x == ENTITY_SAPLINGS && istopv )
	        position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0001, 0.0001, 0.0000, 0.0001, 0.0001, vec3(0.8,0.5,0.4), vec3(0.8,0.3,0.6));
	#endif
	#ifdef WAVING_BROWN_MUSHROOM
	if ( mc_Entity.x == ENTITY_BROWN_MUSHROOM && istopv )
	        position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0001, 0.0001, 0.0000, 0.0001, 0.0001, vec3(0.8,0.5,0.4), vec3(0.8,0.3,0.6));
	#endif
	#ifdef WAVING_RED_MUSHROOM
	if ( mc_Entity.x == ENTITY_RED_MUSHROOM && istopv )
	        position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0001, 0.0001, 0.0000, 0.0001, 0.0001, vec3(0.8,0.5,0.4), vec3(0.8,0.3,0.6));
	#endif
	#ifdef WAVING_POTATOES
    if ( mc_Entity.x == ENTITY_POTATOES && istopv )
	        position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0001, 0.0001, 0.0000, 0.0001, 0.0001, vec3(0.8,0.5,0.4), vec3(0.8,0.3,0.6));
	#endif
	#ifdef WAVING_CARROTS
    if ( mc_Entity.x == ENTITY_CARROTS && istopv )
	        position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0001, 0.0001, 0.0000, 0.0001, 0.0001, vec3(0.8,0.5,0.4), vec3(0.8,0.3,0.6));
	#endif
	#ifdef WAVING_SUGAR_CANES
	if ( mc_Entity.x == ENTITY_SUGAR_CANES && istopv )
	        position.xyz += calcMove(worldpos.xyz, 0.0001, 0.0001, 0.0001, 0.0000, 0.0001, 0.0001, vec3(0.2,0.1,0.1), vec3(0.2,0.1,0.3));
	#endif
	
	
	if (mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_VINES || mc_Entity.x == ENTITY_TALLGRASS || mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE || mc_Entity.x == ENTITY_WHEAT)
	translucent = 1.0;
	/* re-rotate */
	/* projectify */
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;


	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	
	 normal = normalize(gl_NormalMatrix * gl_Normal);

	
}