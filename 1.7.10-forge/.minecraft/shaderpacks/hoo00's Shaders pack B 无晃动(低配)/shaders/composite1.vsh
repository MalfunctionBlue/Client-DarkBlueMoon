#version 120

varying vec4 texcoord;

varying vec4 lightVector;
varying vec3 sunlight;

varying vec3 caustics;

varying float transition_fading;
varying float fog_level;
varying float gp00;
varying float gp11;
varying float gp22;
varying float gp32;
varying float gp2232;
varying float igp00;
varying float igp11;

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform int worldTime;

//////////////////////////////main//////////////////////////////

void main() {
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
    
    texcoord = gl_MultiTexCoord0;
    
    float wtime = float(worldTime);
    transition_fading = 1.0f - (clamp((wtime - 12100.0f) / 300.0f, 0.0f, 1.0f) - clamp((wtime - 13200.0f) / 300.0f, 0.0f, 1.0f) + clamp((wtime - 22500.0f) / 300.0f, 0.0f, 1.0f) - clamp((wtime - 23600.0f) / 300.0f, 0.0f, 1.0f));
    
    if (worldTime < 12800 || worldTime > 23200) {
        lightVector.xyz = normalize(sunPosition);
        lightVector.a = 0.5f;   // distance fog
    }
    else {
        lightVector.xyz = normalize(moonPosition);
        lightVector.a = 1.0f;   // moon glow
    }
    lightVector.a = mix(1.5f, lightVector.a, transition_fading);

    float hour = wtime / 1000.0f + 6.0f;
    if (hour > 24.0f) hour = hour - 24.0f;
    
    ////////////////////sunlight color////////////////////
    const ivec4 ToD[25] = ivec4[25](ivec4(0,15,30,70), //hour,r,g,b
                                    ivec4(1,15,30,70),
                                    ivec4(2,15,30,70),
                                    ivec4(3,15,30,70),
                                    ivec4(4,15,30,70),
                                    ivec4(5,50,60,80),
                                    ivec4(6,245,190,70),
                                    ivec4(7,255,195,80),
                                    ivec4(8,255,200,97),
                                    ivec4(9,255,210,110),
                                    ivec4(10,255,215,125),
                                    ivec4(11,255,225,140),
                                    ivec4(12,255,235,150),
                                    ivec4(13,255,225,140),
                                    ivec4(14,255,215,125),
                                    ivec4(15,255,210,110),
                                    ivec4(16,255,200,97),
                                    ivec4(17,255,195,80),
                                    ivec4(18,245,190,70),
                                    ivec4(19,77,67,194),
                                    ivec4(20,15,30,70),
                                    ivec4(21,15,30,70),
                                    ivec4(22,15,30,70),
                                    ivec4(23,15,30,70),
                                    ivec4(24,15,30,70));
    ivec4 temp = ToD[int(floor(hour))];
    ivec4 temp2 = ToD[int(floor(hour)) + 1];
    
    sunlight = mix(vec3(temp.yzw), vec3(temp2.yzw), (hour - float(temp.x)) / float(temp2.x - temp.x)) / 255.0f;
//    sunlight *= pow(abs(hour - 18.8f) * abs(hour - 5.2f), 0.3f) * 0.12f;     // dawn and dusk
    
    vec4 clight = gbufferModelView * vec4(50.0f, 1.0f, 0.0f, 1.0f);
    clight /= clight.w;
    caustics = normalize(clight.xyz);
    
    fog_level = 0.75f + sin(hour / 12.0f * 3.141597f) * 0.25f;
    
    gp00 = gbufferProjection[0][0] * -0.5f;
    gp11 = gbufferProjection[1][1] * -0.5f;
    gp22 = gbufferProjection[2][2] * 0.5f;
    gp32 = gbufferProjection[3][2] * 0.5f;
    gp2232 = -gp22 - gp32;
    igp00 = -1.0f / gp00;
    igp11 = -1.0f / gp11;
}

//////////////////////////////main//////////////////////////////
