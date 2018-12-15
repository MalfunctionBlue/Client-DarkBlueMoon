#version 120

varying vec4 texcoord;

varying vec3 whitelens;
varying vec3 redlens;
varying vec3 bluelens;

varying vec2 lightPos;
varying vec2 moonPos;

varying float sunTransition;
varying float moonTransition;
varying float lensTransition;

uniform mat4 gbufferProjection;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float aspectRatio;
uniform float rainStrength;

uniform int worldTime;

//////////////////////////////main//////////////////////////////

void main() {
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
    
    texcoord = gl_MultiTexCoord0;
    
    vec4 tpos = vec4(sunPosition, 1.0f) * gbufferProjection;
    lightPos = (tpos.xy / tpos.z) * 0.5f + 0.5f;
    
    vec4 spos = vec4(moonPosition, 1.0f) * gbufferProjection;
    moonPos = (spos.xy / spos.z) * 0.5f + 0.5f;

    float wtime = float(worldTime);
    sunTransition = (1.0f - rainStrength * 0.95f) * (clamp((14200.0f - wtime) / 600.0f, 0.0f, 1.0f) + clamp((wtime - 22350.0f) / 400.0f, 0.0f, 1.0f));
    moonTransition = (1.0f - rainStrength * 0.95f) * (clamp((600.0f - wtime) / 600.0f, 0.0f, 1.0f) + clamp((wtime - 12050.0f) / 400.0f, 0.0f, 1.0f));
    lensTransition = clamp((12300.0f - wtime) / 300.0f, 0.0f, 1.0f) + clamp((wtime - 23700.0f) / 300.0f, 0.0f, 1.0f);
    
    const float white = 0.75f;
    whitelens = vec3(lightPos.x * aspectRatio * white, lightPos.y * white, white);

    const float red = 1.8f;
    const float redPos = -0.523f;
    redlens = vec3(((1.0f - lightPos.x) * (redPos + 1.0f) - (redPos * 0.5f)) * aspectRatio * red, ((1.0f - lightPos.y) * (redPos + 1.0f) - (redPos * 0.5f)) * red, red);

    const float blue = 1.4f;
    const float bluePos = -0.123f;
    bluelens = vec3(((1.0f - lightPos.x) * (bluePos + 1.0f) - (bluePos * 0.5f)) * aspectRatio * blue, ((1.0f - lightPos.y) * (bluePos + 1.0f) - (bluePos * 0.5f)) * blue, blue);
}

//////////////////////////////main//////////////////////////////
