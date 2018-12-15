#version 120

#define MOTIONBLUR
#define MOTIONBLUR_AMOUNT 0.1f

#define DOF
#define USE_HIGH_QUALITY_BLUR

#define SUNRAYS
#define MOONRAYS

#define BLOOM
#define BLOOM_AMOUNT 3.0f

#define LENS

#define CROSSPROCESS
#define CROSSPROCESS_AMOUNT 0.5f

varying vec4 texcoord;

varying vec3 whitelens;
varying vec3 redlens;
varying vec3 bluelens;

varying vec2 lightPos;
varying vec2 moonPos;

varying float sunTransition;
varying float moonTransition;
varying float lensTransition;

uniform sampler2D gcolor;
uniform sampler2D gaux3;
uniform sampler2D depthtex0;

uniform vec3 moonPosition;  // used by moon rays
uniform vec3 sunPosition;   // used by lens and sun rays

uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;

uniform int worldTime;
uniform int isEyeInWater;

float pw = 1.0f / viewWidth;
float ph = 1.0f / viewHeight;

float getDepth(in vec2 coord) {
    return 2.0f * near * far / (far + near - (2.0f * texture2D(depthtex0, coord).x - 1.0f) * (far - near));
}

#ifdef DOF
// HYPERFOCAL = (Focal Distance ^ 2)/(Circle of Confusion * F Stop) + Focal Distance
const float HYPERFOCAL = 3.132f;
const float PICONSTANT = 3.14159f;
vec4 getBlurredColor();
#endif

const float GR_DENSITY = 0.7f;
const float GR_EXPOSURE = 0.4f;
const float GR_FREQUENCY = 0.05f;

//////////////////////////////main//////////////////////////////

void main() {
	vec4 color = texture2D(gcolor, texcoord.st);
#ifdef MOTIONBLUR
    vec2 velocity = texture2D(gaux3, texcoord.st).xy;
    velocity.x = pow(velocity.x, 0.333333333f) * 2.0f - 1.0f;
    velocity.y = pow(velocity.y, 0.333333333f) * 2.0f - 1.0f;
    float speed = length(velocity * vec2(viewWidth, viewHeight)) * MOTIONBLUR_AMOUNT;
    int nsamples = int(clamp(speed, 1.00001f, 20.00001f));
    velocity = normalize(velocity) * vec2(pw, ph) * MOTIONBLUR_AMOUNT;
    vec2 limit = texcoord.st + velocity * (float(nsamples) * 0.5f + 0.5f);
    float fade = 1.0f;
    float weight = 1.0f;
    for (int k = 1; k < nsamples; ++k) {
        vec2 offset = limit + velocity * float(k);
        color += texture2D(gcolor, offset) * fade;
        weight += fade;
        fade *= 0.9f;
    }
    color /= weight;
#endif
#ifdef DOF
    float depth = getDepth(texcoord.st);
    float cursorDepth = getDepth(vec2(0.5f, 0.5f));
    
    // foreground blur = 1/2 background blur. Blur should follow exponential pattern until cursor = hyperfocal -- Cursor before hyperfocal
    // Blur should go from 0 to 1/2 hyperfocal then clear to infinity -- Cursor @ hyperfocal.
    // hyperfocal to inifity is clear though dof extends from 1/2 hyper to hyper -- Cursor beyond hyperfocal
    float mixAmount = 0.0f;
    if (depth < cursorDepth) {
        mixAmount = clamp(2.0f * ((min(cursorDepth, HYPERFOCAL) - depth) / min(cursorDepth, HYPERFOCAL)), 0.0f, 0.66f);
    } else {
        mixAmount =  1.0f - clamp(2.0f - depth / cursorDepth + depth / HYPERFOCAL - cursorDepth / HYPERFOCAL, 0.0f, 0.66f);
    }
    color = mix(color, getBlurredColor(), mixAmount);
#endif
#ifdef SUNRAYS
    float skymask = texture2D(gcolor, vec2(1.0f)).a;
    if ((worldTime > 22350 || worldTime < 14200) && sunPosition.z < 0.0f && skymask > 0.0f) {
        vec2 tex = texcoord.st;
        vec2 delta = (lightPos - tex);
        float decay = max(1.0f - length(delta), 0.00001f);
        delta *= GR_DENSITY * GR_FREQUENCY;
        vec3 rays = vec3(0.0f);
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        
        color.rgb += rays * GR_FREQUENCY * GR_EXPOSURE * sunTransition * decay * decay;
    }
#endif
#ifdef MOONRAYS
    if ((worldTime > 12050 || worldTime < 600) && moonPosition.z < 0.0f) {
        vec2 tex = texcoord.st;
        vec2 delta = (moonPos - tex);
        float decay = max(1.0f - length(delta), 0.00001f);
        delta *= GR_DENSITY * GR_FREQUENCY;
        vec3 rays = vec3(0.0f);
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        tex += delta;
        rays += texture2D(depthtex0, tex).x * texture2D(gcolor, tex).rgb;
        
        color.rgb += rays * 0.4f * GR_FREQUENCY * GR_EXPOSURE * moonTransition * decay * decay;
    }
#endif
#ifdef BLOOM
	int j;
	int i;
	vec4 sum = vec4(0.0f);
    float count = 0.0f;
    for( i= -4 ;i < 4; ++i) {
        for (j = -3; j < 3; ++j) {
            vec2 coord = texcoord.st + vec2(j,i) * 0.004f;
            if(coord.x > 0.0f && coord.x < 1.0f && coord.y > 0.0f && coord.y < 1.0f){
                sum += texture2D(gcolor, coord) * BLOOM_AMOUNT;
                count += 1.0f;
            }
        }
    }
    sum = sum / vec4(count);
	if (color.r < 0.3f) {
		color += sum * sum * 0.012f;
	}
	else {
		if (color.r < 0.5f) {
			color += sum * sum * 0.009f;
		}
		else {
			color += sum * sum * 0.0075f;
		}
	}
#endif
#ifdef LENS
    float white = distance(whitelens.xy, vec2(texcoord.s * aspectRatio * whitelens.z, texcoord.t * whitelens.z));
    float scale = 1.0f - white * 0.5f;  // scale the blue/red lens effects down away from sun
    white = max(0.00001f, 1.0f - white * 2.0f);
    white *= white * white;
    white *= 0.2f * (1.0f - rainStrength) * lensTransition * step(0.0f, moonPosition.z);    // remove moon dark circle
    color.rgb += mix(0.0f, white, color.b) * (float(isEyeInWater) * 5.0f - 1.0f);   // underwater shine

    float sunmask = texture2D(gcolor, vec2(0.0f)).a;
    float red = distance(redlens.xy, vec2(texcoord.s * aspectRatio * redlens.z, texcoord.t * redlens.z));
    red = max(0.00001f, 1.0f - red * 2.0f);
    red *= red * red;
    red *= sunmask * scale;
    color.r += red * 0.8f;
    color.g += red * 0.2f;
    
    float blue = distance(bluelens.xy, vec2(texcoord.s * aspectRatio, texcoord.t) * bluelens.z);
    blue = max(0.00001f, 1.0f - blue * 2.0f);
    blue *= blue * blue;
    blue *= sunmask * 0.7f * scale;
    color.r += blue * 0.64f;
    color.g += blue * 0.2f;
    color.b += blue * 1.5f;
#endif
#ifdef CROSSPROCESS
    color.r += CROSSPROCESS_AMOUNT * (color.r * 0.15f - 0.02f);
    color.g += CROSSPROCESS_AMOUNT * (color.g * 0.15f - 0.02f);
    color.b += CROSSPROCESS_AMOUNT * (color.b * -0.15f + 0.05f);

    float lum = (0.299f * color.r) + (0.587f * color.g) + (0.114f * color.b);
    color.rgb = mix(vec3(lum), color.rgb, 0.75f + 0.25f * lensTransition - 0.1f * texture2D(depthtex0, texcoord.st).x * rainStrength);   // desaturate during night and rain
#endif
    gl_FragColor = vec4(color.rgb, 1.0f);
}

//////////////////////////////main//////////////////////////////

#ifdef DOF
vec4 getBlurredColor() {
	vec4 blurredColor = vec4(0.0f);
	float depth = getDepth(texcoord.xy);
	vec2 aspectCorrection = vec2(1.0f, aspectRatio) * 0.005f;
	vec2 ac0_4 = 0.4f * aspectCorrection;	// 0.4f
#ifdef USE_HIGH_QUALITY_BLUR
	vec2 ac0_4x0_4 = 0.4f * ac0_4;		// 0.16f
	vec2 ac0_4x0_7 = 0.7f * ac0_4;		// 0.28f
#endif
	vec2 ac0_29 = 0.29f * aspectCorrection;	// 0.29f
#ifdef USE_HIGH_QUALITY_BLUR
	vec2 ac0_29x0_7 = 0.7f * ac0_29;	// 0.203f
	vec2 ac0_29x0_4 = 0.4f * ac0_29;	// 0.116f
#endif
	vec2 ac0_15 = 0.15f * aspectCorrection;	// 0.15f
	vec2 ac0_37 = 0.37f * aspectCorrection;	// 0.37f
#ifdef USE_HIGH_QUALITY_BLUR
	vec2 ac0_15x0_9 = 0.9f * ac0_15;	// 0.135f
	vec2 ac0_37x0_9 = 0.37f * ac0_37;	// 0.1369f
#endif
    blurredColor += texture2D(gcolor, texcoord.st + vec2(0.0f, ac0_4.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_4.s, 0.0f));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(0.0f, -ac0_4.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_4.s, 0.0f));
#ifdef USE_HIGH_QUALITY_BLUR
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_4x0_7.s, 0.0f));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(0.0f, -ac0_4x0_7.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_4x0_7.s, 0.0f));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(0.0f, ac0_4x0_7.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_4x0_4.s, 0.0f));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(0.0f, -ac0_4x0_4.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_4x0_4.s, 0.0f));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(0.0f, ac0_4x0_4.t));
#endif
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_29.s, -ac0_29.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_29.s, ac0_29.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_29.s, ac0_29.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_29.s, -ac0_29.t));
#ifdef USE_HIGH_QUALITY_BLUR
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_29x0_7.s, ac0_29x0_7.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_29x0_7.s, -ac0_29x0_7.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_29x0_7.s, ac0_29x0_7.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_29x0_7.s, -ac0_29x0_7.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_29x0_4.s, ac0_29x0_4.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_29x0_4.s, -ac0_29x0_4.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_29x0_4.s, ac0_29x0_4.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_29x0_4.s, -ac0_29x0_4.t));
#endif
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_15.s, ac0_37.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_37.s, ac0_15.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_37.s, -ac0_15.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_15.s, -ac0_37.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_15.s, ac0_37.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_37.s, ac0_15.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_37.s, -ac0_15.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_15.s, -ac0_37.t));
#ifdef USE_HIGH_QUALITY_BLUR
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_15x0_9.s, ac0_37x0_9.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_37x0_9.s, ac0_15x0_9.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_37x0_9.s, -ac0_15x0_9.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_15x0_9.s, -ac0_37x0_9.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_15x0_9.s, ac0_37x0_9.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_37x0_9.s, ac0_15x0_9.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(-ac0_37x0_9.s, -ac0_15x0_9.t));
    blurredColor += texture2D(gcolor, texcoord.st + vec2(ac0_15x0_9.s, -ac0_37x0_9.t));
#endif
#ifdef USE_HIGH_QUALITY_BLUR
		blurredColor *= 0.02439f;	// /= 41.0f;
#else
		blurredColor *= 0.0625f;	// /= 16.0f;
#endif
	return blurredColor;
}
#endif
