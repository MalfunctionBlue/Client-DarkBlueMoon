#version 120

uniform mat4 gbufferModelView;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float rainStrength;
uniform float frameTimeCounter;

uniform int worldTime;
uniform int heldItemId;

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightOffset0;
varying vec3 lightOffset3;
varying vec3 heldLightSpecMultiplier;
varying vec3 sunlight_color;
varying vec3 ambient_color;

varying float heldLightMagnitude;
varying float transition_fading;
varying float ambient_transition;

//////////////////////////////main//////////////////////////////

void main() {
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
    
    texcoord = gl_MultiTexCoord0;

    float wtime = float(worldTime);
    transition_fading = 1.0f - (clamp((wtime - 12100.0f) / 300.0f, 0.0f, 1.0f) - clamp((wtime - 13200.0f) / 300.0f, 0.0f, 1.0f) + clamp((wtime - 22500.0f) / 300.0f, 0.0f, 1.0f) - clamp((wtime - 23600.0f) / 300.0f, 0.0f, 1.0f));
    ambient_transition = 1.0f - (clamp((wtime - 12550.0f) / 250.0f, 0.0f, 1.0f) - clamp((wtime - 12800.0f) / 250.0f, 0.0f, 1.0f) + clamp((wtime - 22950.0f) / 250.0f, 0.0f, 1.0f) - clamp((wtime - 23200.0f) / 250.0f, 0.0f, 1.0f));
    
    float sunlight_radius, moonlight_radius;
    if (worldTime < 12800 || worldTime > 23200) {
        lightVector = normalize(sunPosition);
        sunlight_radius = 0.1f * (1.0f - transition_fading);
        moonlight_radius = 0.06f * (1.0f - transition_fading);
    }
    else {
        lightVector = normalize(moonPosition);
        sunlight_radius = 0.06f * (1.0f - transition_fading);
        moonlight_radius = 0.1f * (1.0f - transition_fading);
    }
    lightOffset0 = normalize(lightVector + (gbufferModelView * vec4(0.0f, sunlight_radius, 0.0f, 0.0f)).xyz);
    
    lightOffset3 = normalize(-lightVector + (gbufferModelView * vec4(0.0f, moonlight_radius, 0.0f, 0.0f)).xyz);
    
    float flicker = cos(-3.142f * (sin(4.935f * frameTimeCounter) + sin(1.885f * frameTimeCounter))) * 0.12f + 1.08f;
    
    if (heldItemId == 50) { // torch
        heldLightMagnitude = 0.5f * flicker;
        heldLightSpecMultiplier = vec3(0.9f, 0.7f, 0.4f);
    }
    else if (heldItemId == 76 || heldItemId == 94) {    // active redstone torch / redstone repeater
        heldLightMagnitude = 0.25f * flicker;
        heldLightSpecMultiplier = vec3(1.0f, 0.2f, 0.2f);
    }
    else if (heldItemId == 89) {    // lightstone
        heldLightMagnitude = 0.5f;
        heldLightSpecMultiplier = vec3(0.9f, 0.9f, 0.5f);
    }
    else if (heldItemId == 10 || heldItemId == 11 || heldItemId == 51) {    // lava / lava / fire
        heldLightMagnitude = 0.7f * flicker;
        heldLightSpecMultiplier = vec3(1.0f, 0.5f, 0.0f);
    }
    else if (heldItemId == 91) {    // jack-o-lantern
        heldLightMagnitude = 0.35f * flicker;
        heldLightSpecMultiplier = vec3(0.7f, 0.5f, 0.3f);
    }
    else if (heldItemId == 326) {   // water bucket
        heldLightMagnitude = 0.0f;
        heldLightSpecMultiplier = vec3(0.0f, 0.2f, 0.6f);
    }
    else if (heldItemId == 327) {   // lava bucket
        heldLightMagnitude = 0.6f * flicker;
        heldLightSpecMultiplier = vec3(1.0f, 0.8f, 0.6f);
    }
    else {
        heldLightMagnitude = 0.0f;
        heldLightSpecMultiplier = vec3(0.0f);
    }

    float hour = wtime / 1000.0f + 6.0f;
    if (hour > 24.0f) hour = hour - 24.0f;
    
    //////////////////////rain color//////////////////////
    float rain_color = 0.4f - cos(hour / 12.0f * 3.141597f) * 0.3f;
    
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
    
    sunlight_color = mix(vec3(temp.yzw), vec3(temp2.yzw), (hour - float(temp.x)) / float(temp2.x - temp.x)) / 255.0f;
    sunlight_color = mix(sunlight_color, vec3(rain_color), rainStrength * 0.8f);
    
    ////////////////////ambient color////////////////////
    const ivec4 ToD2[25] = ivec4[25](ivec4(0,30,60,120), //hour,r,g,b
                                     ivec4(1,30,60,120),
                                     ivec4(2,30,60,120),
                                     ivec4(3,30,60,120),
                                     ivec4(4,30,60,120),
                                     ivec4(5,55,86,135),
                                     ivec4(6,160,170,255),
                                     ivec4(7,160,175,255),
                                     ivec4(8,160,180,260),
                                     ivec4(9,165,190,270),
                                     ivec4(10,190,205,280),
                                     ivec4(11,205,230,290),
                                     ivec4(12,220,255,300),
                                     ivec4(13,205,230,290),
                                     ivec4(14,190,205,280),
                                     ivec4(15,165,190,270),
                                     ivec4(16,150,176,260),
                                     ivec4(17,140,160,255),
                                     ivec4(18,128,150,255),
                                     ivec4(19,77,67,194),
                                     ivec4(20,30,60,120),
                                     ivec4(21,30,60,120),
                                     ivec4(22,30,60,120),
                                     ivec4(23,30,60,120),
                                     ivec4(24,30,60,120));
    ivec4 tempa = ToD2[int(floor(hour))];
    ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
    
    ambient_color = mix(vec3(tempa.yzw), vec3(tempa2.yzw), (hour - float(tempa.x)) / float(tempa2.x - tempa.x)) / 255.0f;
    ambient_color = mix(ambient_color, vec3(rain_color), rainStrength * 0.5f);
}

//////////////////////////////main//////////////////////////////
