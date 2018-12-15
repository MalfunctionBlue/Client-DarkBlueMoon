#version 120

#define BLOCK_ICE            79.0f

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

uniform float rainStrength;
uniform float frameTimeCounter;

attribute vec4 mc_Entity;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;

varying vec3 tangent;
varying vec3 binormal;
varying vec3 normal;
varying vec3 worldpos;

varying float viewdistance;
varying float iswater;
varying float icewater;

//////////////////////////////main//////////////////////////////

void main() {
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;

    color = gl_Color;

    iswater = 0.0f;
    icewater = 0.6f;
    
    if (mc_Entity.x == BLOCK_ICE) {
        icewater = 0.9f; // ice(0.9)
    }
    
    position = gl_ModelViewMatrix * gl_Vertex;  //For bump mapping
    vec4 viewpos = gbufferModelViewInverse * position;  //Un-rotate
    worldpos = viewpos.xyz + cameraPosition;
    
    if (mc_Entity.x == 8.0f || mc_Entity.x == 9.0f) {
        iswater = 1.0f;
        icewater = 1.0f; // water(1.0)
        float magnitude = sin(frameTimeCounter * 0.5818f) * 0.0125f + 0.0375f;
        viewpos.y += sin(6.283f * (frameTimeCounter * 5.0f + worldpos.x * 0.5f + worldpos.z * 0.25f)) * magnitude * 0.4f * rainStrength;
	}
    vec4 viewVertex = gbufferModelView * viewpos; //Re-rotate
    viewdistance = gl_FogFragCoord = length(viewVertex);
    
    gl_Position = gl_ProjectionMatrix * viewVertex;
    
    normal = normalize(gl_NormalMatrix * gl_Normal);
    float normaly = abs(gl_Normal.y);
    tangent  = normalize(gl_NormalMatrix * vec3(gl_Normal.z + normaly,  0.0f, -gl_Normal.x));
    binormal = normalize(gl_NormalMatrix * vec3(0.0f, normaly - 1.0f, normaly));
}

//////////////////////////////main//////////////////////////////
