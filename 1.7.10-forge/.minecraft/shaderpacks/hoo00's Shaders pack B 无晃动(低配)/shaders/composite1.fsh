#version 120

#define WATER_REFLECTIONS

//reflection - raytrace settings
const float stp = 0.075f; // starting step (0.1f)
const float ref = 0.1007f; // refinement (step reduced by 0.1f)
const float inc = 2.4f; // log increment factor (log 2.4f search)
const int maxf = 5;     // number of refinements (5 + 1 times)
const int eff = 60;     // effort (do 60 number of searches)

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

uniform sampler2D gcolor;
uniform sampler2D gdepth;   // heavily bump water normal from gbuffer_water.fsh
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;    // rain from gbuffer_weather.fsh
uniform sampler2D gaux3;    // clouds from gbuffer_textured.fsh
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float far;
uniform float near;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;

float pw = 1.0f / viewWidth;
float ph = 1.0f / viewHeight;

vec3 proj(in vec3 pos) {
    return vec3(pos.x * gp00, pos.y * gp11, gp2232) / pos.z + 0.5f;
}

vec3 invproj(in vec3 p) {
    vec3 pos = p - 0.5f;
    float z = gp32 / (pos.z + gp22);
    return vec3(pos.x * igp00, pos.y * igp11, -1.0f) * z;
}

float fadeout(in vec2 coord) {
    float cdist = distance(coord, vec2(0.5f));
    return 1.01f + cdist * cdist * (cdist - 1.0f) * 6.8f;
}

vec4 raytrace(in vec3 eye, in vec3 refvector, in float eyez) {
    float delta = stp;
    float sum = delta * 1.5f;  // offset to remove artifacts
    int sr = 0;
    for(int i = 0; i < eff; ++i) {
        vec3 offset = eye + sum * refvector;
        vec3 pos = proj(offset);
        if (pos.z > 1.0f || pos.z < 0.0f || pos.y > 1.0f || pos.y < 0.0f || pos.x > 1.0f || pos.x < 0.0f) break;
        float posz = texture2D(depthtex2, pos.st).r;    // remove objects before reflection zone
        float dist = length(offset) - length(invproj(vec3(pos.st, posz)));    // depthtex2 - no hand effect
        if (posz > eyez - 0.001f && dist > -0.0001f && dist < delta * sum + float(sr) * -0.0225f + 0.15f) {
            if (sr > maxf) {
                vec4 color = texture2D(composite, pos.st);
                color.a = fadeout(pos.st);
                return color;
            }
            ++sr;
            sum -= delta;
            delta *= ref;
        }
        delta *= inc;
        sum += delta;
    }
    return vec4(0.0f);
}

float ld(in float depth) {
    return (2.0f * near) / (far + near - depth * (far - near));
}

//////////////////////////////main//////////////////////////////

void main() {
    vec4 color = texture2D(gcolor, texcoord.st);

    float matflag = texture2D(gaux1, texcoord.xy).g;
    float hand = 1.0f;
    if(matflag > 0.35f && matflag < 0.45f) {
        hand = 0.3f;    // scale rain effect on hand (0.0f - 0.9f)
    }
    vec3 eye = invproj(vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r));
    if (isEyeInWater < 1) {
        vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;

        const float fland = 0.05f;
        const float fwater = 0.95f;
        if (matflag > fland && matflag < fwater && hand > 0.9f) {
            float ssao = 0.0f;
            float range = clamp(distance(proj(eye + vec3(1.0f)).xy, texcoord.xy), 7.5f * pw, 60.0f * pw);
            float dist = ld(texture2D(depthtex0, texcoord.st).r);
            for (float i = 0.0f; i < 5.1f; i += 1.3f) {
                for (float j = 0.25f; j < 1.1f; j += 0.25f) {
                    vec2 offset = vec2(cos(float(i)), sin(float(i))) * (float(j) * 0.25f) * range + texcoord.xy;
                    vec3 offpos = invproj(vec3(offset, texture2D(depthtex0, offset).r));
                    float angle = min(1.0 - dot(normal, normalize(offpos - eye)), 1.0f);
                    float ldist = min(abs(ld(texture2D(depthtex0, offset).r) - dist) * 65.0f, 1.0f);
                    float effect = min(ldist * ldist + angle * angle, 1.0f);
                    ssao += effect * effect * effect;
                }
            }
            ssao *= 0.0625f;
            color.rgb *= ssao * 0.5f + 0.5f;
        }

        color.rgb += texture2D(gaux2, texcoord.xy).rgb * texture2D(gaux2, texcoord.xy).a * 0.5f * hand;	// draw rain

        vec3 fogclr = mix(gl_Fog.color.rgb, vec3(0.3f, 0.4f, 0.5f), 0.2f);
        vec3 neye = normalize(eye);
        vec3 nnormal = normalize(normal);
        const float freflect = 0.85f;
        if (matflag > freflect) {
#ifdef WATER_REFLECTIONS
            float fresnel = clamp(pow(1.0f + dot(nnormal, neye), 5.0f), 0.0f, 1.0f);
            vec3 fnormal = mix(normal, texture2D(gdepth, texcoord.st).rgb * 2.0f - 1.0f, fresnel);
            vec4 reflection = raytrace(eye, normalize(reflect(neye, normalize(fnormal))), texture2D(depthtex2, texcoord.st).r);
            reflection.rgb = mix(fogclr, reflection.rgb, reflection.a); // add sky/fog color to reflection
            float reflectionStrength = matflag * 5.0f - 4.0f;
            color.rgb += reflection.rgb * fresnel * reflectionStrength * (1.0f - rainStrength * 0.85f);
            //color.r = mod(-eye.z, 5.0f) > 0.95 * 5.0f? 1.0f : color.r;   // show lines on water
            color.rgb += color.a * reflection.rgb * reflectionStrength * 0.5f;  // spec from composite.fsh here to remove shadows
            color.r *= 0.8f;    // set 80 percent red on water
#endif
        }
        if (matflag > fwater) {
            float f0 = 0.3f * max(dot(caustics, nnormal), 0.00001f); // basic caustics
            f0 *= step(f0, 0.02f);  // remove artifacts from flowing water
            color.g += f0;
        }
        if (fogMode == 0 && hand > 0.9f) {
            vec3 feye = mix(eye, invproj(vec3(texcoord.st, texture2D(depthtex1, texcoord.st).r)), texture2D(gaux3, texcoord.st).a); // fog cloud needs depthtex1, water needs depthtex0
            vec4 worldpos = gbufferModelViewInverse * vec4(feye, 1.0f);
            float density = 96.0f / max(120.0f + worldpos.y, 52.7f) - 0.8f;
            float dist = (1.0f + wetness * 0.2f + rainStrength * 0.2f) * 280.0f / clamp(280.0f - length(feye) * fog_level * 215.0f / far, 132.0f, 242.0f) - 1.15f + wetness * 0.1f;
            float fog = clamp(mix(density, dist, 0.6f), 0.0f, 1.0f);
            fog *= 1.0f - 0.5f * step(matflag, fland) * (1.0f - rainStrength * 0.9f);  // reduce fog in sky
            float volumetric_cone = pow(max(dot(neye, lightVector.xyz), 0.00001f), 5.0f) * lightVector.a;
            fogclr += sunlight * transition_fading * volumetric_cone * (0.9f - rainStrength * 0.8f);   // inject moon color into the fog
            color.rgb = mix(color.rgb, fogclr, fog);
            //float range = length(feye);
            //color.r = (range > 175.0f && range < 176.0f) ? 1.0f : color.r;
            //color.g = (worldpos.y > -52.0f && worldpos.y < -51.0f) ? 1.0f : color.g;
            //color.b = (worldpos.y > -0.1f && worldpos.y < 0.0f) ? 1.0f : color.b;
        }
    }
    else {  // eye in water
        color = texture2D(gcolor, vec2(texcoord.s + 0.001f * sin(frameTimeCounter * 5.0f + texcoord.t * 20.0f), texcoord.t));   // basic underwater wave
    }

    //calculate sun occlusion at vec2(0.0f) for lens and sky occlusion at vec2(1.0f) for sunrays
    float visiblesun = 0.0f;
    vec4 tpos = vec4(sunPosition, 1.0f) * gbufferProjection; // a transposed projection
    vec2 lightPos = (tpos.xy / tpos.z) * 0.5f + 0.5f;
    if (((texcoord.x < pw && texcoord.y < ph) || ((texcoord.x + pw) > 1.0f && (texcoord.y + ph) > 1.0f)) && (lightPos.x < 1.4f && lightPos.x > -0.4f && lightPos.y < 1.4f && lightPos.y > -0.4f && sunPosition.z < -0.4f)) {
        const float fsun = 0.05f;
        float mult = 12.0f + 144.0f * texcoord.x;
        for (int i = 0; i < 9; ++i) {
            for (int j = 0; j < 9; ++j) {
                vec2 offsun = lightPos + vec2(pw * (float(i) - 4.0f) * mult, ph * (float(j) - 4.0f) * mult);
                if (offsun.x < 1.0f && offsun.x > 0.0f && offsun.y < 1.0f && offsun.y > 0.0f && texture2D(gaux1, offsun).g < fsun) {
                    visiblesun += 1.0f;
                }
            }
        }
        visiblesun /= 81.0f;    // 9.0f x 9.0f = 81.0f
        visiblesun *= 1.0f - rainStrength * 0.9f;
        visiblesun *= clamp((13050.0f - float(worldTime)) * 0.002f, 0.0f, 1.0f) + clamp((float(worldTime) - 22950.0f) * 0.002f, 0.0f, 1.0f);
    }
    
    vec4 wpos = gbufferModelViewInverse * vec4(eye, 1.0f);  // screen space motion blur
    wpos.xyz += cameraPosition - previousCameraPosition;
    vec4 prevPos = gbufferPreviousProjection * gbufferPreviousModelView * wpos;
    vec2 velocity = vec2(prevPos.xy / prevPos.w * 0.5f + 0.5f - texcoord.xy);
    velocity = max(velocity * 0.5f + 0.5f, 0.00001f);
    velocity.x = pow(velocity.x, 3.0f);
    velocity.y = pow(velocity.y, 3.0f);

/* DRAWBUFFERS:06 */
    gl_FragData[0] = vec4(color.rgb, visiblesun);    // gcolor in final.fsh
    gl_FragData[1] = vec4(velocity, 1.0f, 1.0f);  // gaux3 in final.fsh
}

//////////////////////////////main//////////////////////////////
