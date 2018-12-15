#version 120

const int gcolorFormat = 1; // Internal - RGB8
const int gdepthFormat = 1; // Internal - RGB8
const int gnormalFormat = 2; // Internal - RGB16
const int compositeFormat = 1; // Internal - RGB8
const float	ambientOcclusionLevel = 0.1f;   // Internal
const float	sunPathRotation	= -23.4f;   // Internal

const int shadowMapResolution = 2048;   // Internal
const float shadowDistance = 128.0f; // Internal

#define SUNLIGHTAMOUNT 1.1f

const vec3 torchcolor = vec3(1.5f,0.9f,0.3f);

#define TORCH_POWER 2.0f
#define TORCH_INTENSITY 1.0f

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 lightVector;
varying vec3 lightOffset0;
varying vec3 lightOffset3;
varying vec3 sunlight_color;
varying vec3 ambient_color;
varying vec3 heldLightSpecMultiplier;
varying float heldLightMagnitude;
varying float transition_fading;
varying float ambient_transition;

uniform sampler2D gcolor;
uniform sampler2D gdepth;   // specularity - red green blue gloss
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D shadow;
uniform sampler2D watershadow;
uniform sampler2D shadowcolor;

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform float far;
uniform float near;
uniform float rainStrength;
uniform float wetness;

uniform int isEyeInWater;

float gp22 = gbufferProjection[2][2] * 0.5f;
float gp32 = gbufferProjection[3][2] * 0.5f;
float igp00 = 2.0f / gbufferProjection[0][0];
float igp11 = 2.0f / gbufferProjection[1][1];

vec3 invproj(in vec3 p) {
    vec3 pos = p - 0.5f;
    float z = gp32 / (pos.z + gp22);
    return vec3(pos.x * igp00, pos.y * igp11, -1.0f) * z;
}

float nspec(in vec3 pos, in vec3 lvector, in vec3 normal) {
    
    // half vector
    vec3 cHalf = normalize(lvector + pos);
    float normalDotHalf = dot(normal, cHalf);
    
    // beckmann's distribution function D
    float normalDotHalf2 = normalDotHalf * normalDotHalf;
    float roughness2 = 0.25f;
    float exponent = -(1.0f - normalDotHalf2) / (normalDotHalf2 * roughness2);
    float D = exp(exponent) / (roughness2 * normalDotHalf2 * normalDotHalf2);
	
    // fresnel term F
    float halfDotEye = dot(cHalf, pos);
    float F = clamp(pow(1.0f - halfDotEye, 5.0f), 0.0f, 1.0f);
    
    // self shadowing term G
    float normalDotEye = dot(normal, pos);
    float normalDotLight = dot(normal, lvector);
    float X = 2.0f * normalDotHalf / halfDotEye;
    float G = min(1.0f, min(X * normalDotLight, X * normalDotEye));
    const float pi = 3.1415927f;
    float CookTorrance = (D * F * G) / (pi * normalDotEye);
	
    return max(CookTorrance / pi, 0.00001f);
}

float ld(in float depth) {
    return (2.0f * near) / (far + near - depth * (far - near));
}

//////////////////////////////main//////////////////////////////

void main() {
    vec3 color = texture2D(gcolor, texcoord.st).rgb;
    vec3 compo = texture2D(composite, texcoord.st).rgb;
    float spec = 0.0f;

    vec4 aux = texture2D(gaux1, texcoord.st);
    float no_hand = float(aux.g < 0.35f || aux.g > 0.45f);
    
    if (isEyeInWater < 1) {
        const float fland = 0.05f;
        if (aux.g > fland) {
            vec3 total_effect = mix(vec3(0.22f), ambient_color, 0.22f); // sky and indoor ambient light

            vec3 shading = vec3(1.0f);
            vec3 eye = invproj(vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r));
            float dist = length(eye);
            vec4 worldpos = gbufferModelViewInverse * vec4(eye, 1.0f);
            worldpos = shadowModelView * worldpos;
            float comparedepth = -worldpos.z;
            vec4 warp = shadowProjection * worldpos;
            warp /= warp.w;
            vec2 shadowPos = warp.st * 0.5f + 0.5f;
            const float fshadow = 0.15f;
            if (dist < shadowDistance && comparedepth > 0.0f && aux.g > fshadow && shadowPos.s < 1.0f && shadowPos.s > 0.0f && shadowPos.t < 1.0f && shadowPos.t > 0.0f) {
                const vec2 circle_offset0 = vec2(-0.875f, 0.875f);  // shadow sampling
                const vec2 circle_offset1 = vec2(-0.5f, 0.125f);
                const vec2 circle_offset2 = vec2(-0.125f, -0.75f);
                const vec2 circle_offset3 = vec2(0.375f, 0.5f);
                const vec2 circle_offset4 = vec2(0.75f, -0.375f);
                float offset = 0.1f / float(shadowMapResolution);
                
                float shadingwater = 0.0f;
                shadingwater += clamp(comparedepth - (0.05f + texture2D(watershadow, shadowPos + circle_offset0 * offset).z * 255.95f), 0.0f, 1.0f);
                shadingwater += clamp(comparedepth - (0.05f + texture2D(watershadow, shadowPos + circle_offset1 * offset).z * 255.95f), 0.0f, 1.0f);
                shadingwater += clamp(comparedepth - (0.05f + texture2D(watershadow, shadowPos + circle_offset2 * offset).z * 255.95f), 0.0f, 1.0f);
                shadingwater += clamp(comparedepth - (0.05f + texture2D(watershadow, shadowPos + circle_offset3 * offset).z * 255.95f), 0.0f, 1.0f);
                shadingwater += clamp(comparedepth - (0.05f + texture2D(watershadow, shadowPos + circle_offset4 * offset).z * 255.95f), 0.0f, 1.0f);
                shadingwater = max(0.0f, 1.0f - shadingwater * 0.4f);
                
                float shadingsharp = 0.0f;
                shadingsharp += clamp(comparedepth - (0.05f + (texture2D(shadow, shadowPos + circle_offset0 * offset).z) * 255.95f), 0.0f, 1.0f);
                shadingsharp += clamp(comparedepth - (0.05f + (texture2D(shadow, shadowPos + circle_offset1 * offset).z) * 255.95f), 0.0f, 1.0f);
                shadingsharp += clamp(comparedepth - (0.05f + (texture2D(shadow, shadowPos + circle_offset2 * offset).z) * 255.95f), 0.0f, 1.0f);
                shadingsharp += clamp(comparedepth - (0.05f + (texture2D(shadow, shadowPos + circle_offset3 * offset).z) * 255.95f), 0.0f, 1.0f);
                shadingsharp += clamp(comparedepth - (0.05f + (texture2D(shadow, shadowPos + circle_offset4 * offset).z) * 255.95f), 0.0f, 1.0f);
                shadingsharp = max(0.0f, 1.0f - shadingsharp * 0.8f);
                
                vec3 shadowColorSample = texture2D(shadowcolor, shadowPos).rgb;
                shading = shadowColorSample * (shadingsharp - shadingwater) + shadingwater;
            }
            shading = clamp(shading, 0.0f, 1.0f);
            vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;
            float NdotL = dot(normal, lightVector);
            float translucent = float(aux.g > 0.25f && aux.g < 0.35f);
            float sss_transparency = 0.75f * translucent; //subsurface scattering amount
            vec3 neye = normalize(eye);
            float sss = pow(max(dot(neye, lightVector), 0.00001f), 20.0f) * sss_transparency * clamp(-NdotL, 0.0f, 1.0f) * 4.0f;
            float distof2 = clamp(1.0f - dist / (shadowDistance * 0.75f), 0.0f, 1.0f);
            float sss_fade = pow(distof2, 0.2f);
            sss = mix(0.0f, sss, min(sss_fade + 0.5f, 1.0f));
            total_effect += sss * sunlight_color * shading * (1.0f - rainStrength * 0.9f) * ambient_transition; // sub surface scattering light
            
            float shadow_fade = clamp(12.0f * (1.0f - dist / shadowDistance), 0.0f, 1.0f);
            float sunlight_direct = max(NdotL, 0.00001f);
            total_effect += sunlight_color * (1.0f - wetness * 0.1f - rainStrength * 0.9f) * mix(vec3(1.0f), shading, shadow_fade) * SUNLIGHTAMOUNT * transition_fading * mix(sunlight_direct, 0.75f, translucent);   // direct sun light
            
            vec3 nnormal = normalize(normal);
            total_effect += max(dot(nnormal, -neye), 0.00001f) * heldLightSpecMultiplier * heldLightMagnitude / dist * no_hand;    // held light

            // spectral reflection on water - for sun and moon only
            const float fspec = 0.85f;
            if (aux.g > fspec) {
                if (transition_fading > 0.999f) {
                    spec = nspec(-neye, lightVector, nnormal);
                }
                else {
                    spec = nspec(-neye, lightOffset0, nnormal) + nspec(-neye, lightOffset3, nnormal);
                }
                spec *= (1.0f - rainStrength);
            }
            else {
                vec4 specularity = mix(texture2D(gdepth, texcoord.st), vec4(ambient_color, 2.0f), 0.5f);
                total_effect += (1.0f - rainStrength) * pow(nspec(-neye, lightVector, nnormal), specularity.a) * specularity.rgb * shading * no_hand * transition_fading;
            }
            vec3 compo_effect = total_effect;
            compo_effect += pow(aux.b * (1.0f - translucent), TORCH_POWER) * TORCH_INTENSITY * torchcolor;
            compo *= mix(vec3(1.0f), compo_effect, no_hand);
            total_effect += pow(aux.b, TORCH_POWER) * TORCH_INTENSITY * torchcolor;    // torch light
            color *= total_effect;
        }
        else {
            // sky and raining
            color = mix(color, gl_Fog.color.rgb, rainStrength * 0.1f);
            compo = mix(compo, gl_Fog.color.rgb, rainStrength * 0.1f);
        }
    }
    else {  // eye in water
        vec3 watercolor = vec3(0.15f, 0.25f, 0.45f) * 0.5f * (ambient_color.r + ambient_color.g + ambient_color.b);
        float log_depth = ld(texture2D(depthtex2, texcoord.st).r) * 1.45f;
        float depth_diff = min(log_depth * log_depth, 1.0f) * no_hand;
        color = vec3(0.4f, 0.9f, 0.7f) * mix(color * vec3(0.3f, 0.35f, 0.7f), watercolor, depth_diff);
    }

    color = clamp(color, 0.0f, 1.0f);
    compo = clamp(compo, 0.0f, 1.0f);

/* DRAWBUFFERS:03 */
    gl_FragData[0] = vec4(color, spec);	// gcolor in composite1.fsh
    gl_FragData[1] = vec4(compo, spec);	// composite in composite1.fsh
}

//////////////////////////////main//////////////////////////////
