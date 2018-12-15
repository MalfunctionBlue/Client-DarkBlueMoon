#version 120

//#define WAVING_WORLD

#define BLOCK_SAPLINGS        6.0f
#define BLOCK_LAVAFLOWING    10.0f
#define BLOCK_LAVASTILL      11.0f
#define BLOCK_LEAVES         18.0f
#define BLOCK_TALLGRASS      31.0f
#define BLOCK_DEADBUSH       32.0f
#define BLOCK_DANDELION      37.0f
#define BLOCK_ROSE           38.0f
#define BLOCK_BROWN_MUSHROOM 39.0f
#define BLOCK_RED_MUSHROOM   40.0f
#define BLOCK_FIRE           51.0f
#define BLOCK_WHEAT          59.0f
#define BLOCK_SUGAR_CANES    83.0f
#define BLOCK_VINES         106.0f
#define BLOCK_LILYPAD       111.0f
#define BLOCK_CARROTS       141.0f
#define BLOCK_POTATOES      142.0f
#define BLOCK_DBL_TALLGRASS 175.0f

#define BLOCK_GLASS          20.0f
#define BLOCK_DIAMOND        57.0f
#define BLOCK_PACKED_ICE    174.0f

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float frameTimeCounter;

uniform int worldTime;
uniform int heldItemId;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

varying mat3 tbnMatrix;

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 color;

varying vec3 lightVector;

varying float translucent;
varying float isglass;

const float PI = 3.141592653589793f;
float pi2wt;

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    float d0 = sin(pi2wt * f0);
    float d1 = sin(pi2wt * f1);
    float d2 = sin(pi2wt * f2);
    float magnitude = sin(pi2wt * fm + pos.x * 0.5f + pos.z * 0.5f + pos.y * 0.5f) * mm + ma;
    return vec3(sin(pi2wt * f3 + d0 + d1 - pos.x + pos.z + pos.y), sin(pi2wt * f5 + d2 + d0 + pos.z + pos.y - pos.y), sin(pi2wt * f4 + d1 + d2 + pos.x - pos.z + pos.y)) * magnitude;
}

vec3 calcLeaveWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0) {
    float p0 = pi2wt * f0;
    float d0 = p0 + sin(p0) * 2.0f;
    float magnitude = sin(pi2wt * fm + pos.x * 0.5f + pos.z * 0.5f + pos.y * 0.5f) * mm + ma;
    return vec3(sin(d0 - pos.x + pos.z + pos.y), sin(d0 + pos.z + pos.y - pos.y), sin(d0 + pos.x - pos.z + pos.y)) * magnitude;
}

vec3 calcXZWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4) {
    float d0 = sin(pi2wt * f0);
    float d1 = sin(pi2wt * f1);
    float d2 = sin(pi2wt * f2);
    float magnitude = sin(pi2wt * fm + pos.x * 0.5f + pos.z * 0.5f + pos.y * 0.5f) * mm + ma;
    return vec3(sin(pi2wt * f3 + d0 + d1 - pos.x + pos.z + pos.y), 0.0f, sin(pi2wt * f4 + d1 + d2 + pos.x - pos.z + pos.y)) * magnitude;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    pi2wt = PI * frameTimeCounter * 48.0f;
    vec3 move1 = calcWave(pos, 0.0027f, 0.04f, 0.04f, 0.0127f, 0.0089f, 0.0114f, 0.0063f, 0.0224f, 0.0015f) * amp1;
    vec3 move2 = calcWave(pos + move1, 0.0348f, 0.04f, 0.04f, f0, f1, f2, f3, f4, f5) * amp2;
    return move1 + move2;
}

vec3 calcLeaveMove(in vec3 pos, in float f0, in vec3 amp1, in vec3 amp2) {
    pi2wt = PI * frameTimeCounter * 48.0f;
    vec3 move1 = calcWave(pos, 0.0027f, 0.04f, 0.04f, 0.0127f, 0.0089f, 0.0114f, 0.0063f, 0.0224f, 0.0015f) * amp1;
    vec3 move2 = calcLeaveWave(pos + move1, 0.0348f, 0.04f, 0.04f, f0) * amp2;
    return move1 + move2;
}

vec3 calcXZMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in vec3 amp1, in vec3 amp2) {
    pi2wt = PI * frameTimeCounter * 48.0f;
    vec3 move1 = calcXZWave(pos, 0.0027f, 0.04f, 0.04f, 0.0127f, 0.0089f, 0.0114f, 0.0063f, 0.0224f) * amp1;
    vec3 move2 = calcXZWave(pos + move1, 0.0348f, 0.04f, 0.04f, f0, f1, f2, f3, f4) * amp2;
    return move1 + move2;
}

vec3 calcWaterMove(in vec3 pos) {
	float fy = fract(pos.y + 0.001f);
	if (fy > 0.002f)
	{
		float wave = 0.025f * sin(2.0f * PI * (float(worldTime) / 86.0f + pos.x / 7.0f + pos.z / 13.0f)) + 0.025f * sin(2.0f * PI * (float(worldTime) / 60.0f + pos.x / 11.0f + pos.z / 5.0f));
		return vec3(0.0f, clamp(wave, -fy, 1.0f - fy), 0.0f);
	}
    return vec3(0.0f);
}

//////////////////////////////main//////////////////////////////

void main() {
    lightVector = normalize((worldTime < 12800 || worldTime > 23200) ? sunPosition : moonPosition);
    
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    
    color = gl_Color;
    
    bool istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t;
    
    /* un-rotate */
    vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    vec3 worldpos = position.xyz + cameraPosition;

    float wavingtop = float(mc_Entity.x == BLOCK_SAPLINGS || mc_Entity.x == BLOCK_BROWN_MUSHROOM || mc_Entity.x == BLOCK_RED_MUSHROOM || mc_Entity.x == BLOCK_CARROTS || mc_Entity.x == BLOCK_POTATOES || mc_Entity.x == BLOCK_FIRE || mc_Entity.x == BLOCK_SUGAR_CANES);
    
    float waving = float(mc_Entity.x == BLOCK_LAVAFLOWING || mc_Entity.x == BLOCK_LAVASTILL || mc_Entity.x == BLOCK_LILYPAD);

    translucent = 0.3f * float(mc_Entity.x == BLOCK_LEAVES || mc_Entity.x == BLOCK_VINES || mc_Entity.x == BLOCK_TALLGRASS || mc_Entity.x == BLOCK_DBL_TALLGRASS || mc_Entity.x == BLOCK_DEADBUSH || mc_Entity.x == BLOCK_DANDELION || mc_Entity.x == BLOCK_ROSE || mc_Entity.x == BLOCK_WHEAT);    // lit(0.3f)
    
#ifdef WAVING_WORLD
    position.xyz +=
    wavingtop + waving + translucent < 0.1f ?
    vec3(0.0f) :
    
    translucent > 0.1f ?
    (
     mc_Entity.x == BLOCK_LEAVES || mc_Entity.x == BLOCK_VINES ?
     calcLeaveMove(worldpos, 0.0001f, vec3(0.1f, 0.2f, 0.1f), vec3(0.1f, 0.0f, 0.2f)) :
     !istopv ? vec3(0.0f) :
     mc_Entity.x == BLOCK_WHEAT ?
     calcMove(worldpos, 0.0001f, 0.0f, 0.0002f, 0.0f, 0.0001f, 0.0f, vec3(1.8f, 1.0f, 1.8f) * 0.125f, vec3(1.4f, 1.0f, 1.4f) * 0.125f) :
     //mc_Entity.x == BLOCK_DANDELION || mc_Entity.x == BLOCK_ROSE ?
     calcXZMove(worldpos, 0.0001f, 0.0f, 0.0001f, 0.0f, 0.0001f, vec3(1.8f, 1.5f, 2.0f) * 0.2f, vec3(1.8f, 1.3f, 1.6f) * 0.2f)
     //mc_Entity.x == BLOCK_TALLGRASS || mc_Entity.x == BLOCK_DBL_TALLGRASS || mc_Entity.x == BLOCK_DEADBUSH ?
     //calcXYMove(worldpos, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, vec3(1.7f, 1.4f, 1.9f) * 0.2f, vec3(1.8f, 1.3f, 1.6f) * 0.2f)
    ) :
    
    waving > 0.1f ?
    (
     mc_Entity.x == BLOCK_LILYPAD ?
     calcWaterMove(worldpos) * 0.5f :
     //mc_Entity.x == BLOCK_LAVAFLOWING || mc_Entity.x == BLOCK_LAVASTILL ?
     calcWaterMove(worldpos) * 0.25f
    ) :
    
    //wavingtop > 0.1f ?
    (
     !istopv ? vec3(0.0f) :
     mc_Entity.x == BLOCK_FIRE ?
     calcMove(worldpos, 0.0105f, 0.0096f, 0.0087f, 0.0063f, 0.0097f, 0.0156f, vec3(1.2f, 0.4f, 1.2f), vec3(0.8f)) :
     mc_Entity.x == BLOCK_SUGAR_CANES ?
     calcXZMove(worldpos, 0.0001f, 0.0001f, 0.0001f, 0.0f, 0.0001f, vec3(0.2f, 0.1f, 0.1f), vec3(0.2f, 0.1f, 0.3f)) :
     //mc_Entity.x == BLOCK_SAPLINGS || mc_Entity.x == BLOCK_BROWN_MUSHROOM || mc_Entity.x == BLOCK_RED_MUSHROOM || mc_Entity.x == BLOCK_POTATOES || mc_Entity.x == BLOCK_CARROTS ?
     calcXZMove(worldpos, 0.0001f, 0.0001f, 0.0001f, 0.0f, 0.0001f, vec3(0.8f, 0.5f, 0.4f) * 0.25f, vec3(0.8f, 0.3f, 0.6f) * 0.25f)
    );
#endif
    
    isglass = 0.9f * float(mc_Entity.x == BLOCK_PACKED_ICE || mc_Entity.x == BLOCK_GLASS || mc_Entity.x == BLOCK_DIAMOND);  // ice(0.9f)

	/* re-rotate */
    vec4 viewVertex = gbufferModelView * position;
    float viewdistance = length(viewVertex);
    
    if (heldItemId == 10 || heldItemId == 11 || heldItemId == 50 || heldItemId == 51 || heldItemId == 76 || heldItemId == 91 || heldItemId == 94 || heldItemId == 89 || heldItemId == 327) { // lighting correction
        lmcoord.s += mix(1.5f / viewdistance - 0.05f, 0.0f, lmcoord.s);
    }
    
    /* projectify */
    gl_Position = gl_ProjectionMatrix * viewVertex;

    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
    float normaly = abs(gl_Normal.y);
    vec3 tangent  = normalize(gl_NormalMatrix * vec3(gl_Normal.z + normaly,  0.0f, -gl_Normal.x));
    vec3 binormal = normalize(gl_NormalMatrix * vec3(0.0f, normaly - 1.0f, normaly));
    tbnMatrix = mat3(tangent, binormal, normal);
}

//////////////////////////////main//////////////////////////////
