//Credits
//God Rays: Blizzar
//Depth offield: Azraeil.
//Bloom: CosmicSpore
//Modification: MrMeep_x3


//DeDelner: Fixed DOF, fixed water reflections and modified God Rays al lot much better!
/*


*/
#version 120

//To disable an effect place 2 slashes before it's line
#define DOF
#define GODRAYS
//#define MOONRAYS  //Very buggy!
   #define GODRAYS_DECAY 0.90
   #define GODRAYS_LENGHT 1.0
   #define GODRAYS_BRIGHTNESS 0.2
   #define GODRAYS_SAMPLES 32            // More samples are finer, but need more performance.
#define BLOOM
   #define BLOOM_AMOUNT 4
#define CROSSPROCESS

// If you want a higher quality blur for DOF, remove the forward slashes from the following line:
#define USE_HIGH_QUALITY_BLUR

uniform sampler2D depthtex0;
uniform sampler2D composite;
uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform float worldTime;
uniform float rainStrength;
uniform float aspectRatio;
uniform float near;
uniform float far;
varying vec4 texcoord;

float getDepth(vec2 coord) {
    return 2.0 * near * far / (far + near - (2.0 * texture2D(depthtex0, coord).x - 1.0) * (far - near));
}

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

#ifdef DOF
// HYPERFOCAL = (Focal Distance ^ 2)/(Circle of Confusion * F Stop) + Focal Distance
const float HYPERFOCAL = 3.132;
const float PICONSTANT = 3.14159;
vec4 getBlurredColor();
vec4 getSample(vec2 coord, vec2 aspectCorrection);
vec4 getSampleWithBoundsCheck(vec2 offset);
float samples = 0.0;
vec2 space;
#endif

#ifdef GODRAYS
const float GR_DECAY    = 1.0*GODRAYS_DECAY;
const float GR_DENSITY  = 1.0*GODRAYS_LENGHT;
const float GR_EXPOSURE = 1.0*GODRAYS_BRIGHTNESS;
const int GR_SAMPLES    = 1*GODRAYS_SAMPLES;
#endif

void main() {
	vec4 color = texture2D(composite, texcoord.st);
#ifdef DOF
	float depth = getDepth(texcoord.st);
	    
	float cursorDepth = getDepth(vec2(0.5, 0.5));
    
    // foreground blur = 1/2 background blur. Blur should follow exponential pattern until cursor = hyperfocal -- Cursor before hyperfocal
    // Blur should go from 0 to 1/2 hyperfocal then clear to infinity -- Cursor @ hyperfocal.
    // hyperfocal to inifity is clear though dof extends from 1/2 hyper to hyper -- Cursor beyond hyperfocal
    
    float mixAmount = 0.0;
    
    if (depth < cursorDepth) {
    	mixAmount = clamp(2.0 * ((clamp(cursorDepth, 0.0, HYPERFOCAL) - depth) / (clamp(cursorDepth, 0.0, HYPERFOCAL))), 0.0, 1.0);
	} else if (cursorDepth == HYPERFOCAL) {
		mixAmount = 0.0;
	} else {
		mixAmount =  1.0 - clamp((((cursorDepth * HYPERFOCAL) / (HYPERFOCAL - cursorDepth)) - (depth - cursorDepth)) / ((cursorDepth * HYPERFOCAL) / (HYPERFOCAL - cursorDepth)), 0.0, 1.0);
	}
    
    if (mixAmount != 0.0) {
		color = mix(color, getBlurredColor(), mixAmount);
   	}
#endif

#ifdef GODRAYS
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 pos1 = tpos.xy/tpos.z;
		vec2 lightPos = pos1*0.5+0.5;
    float threshold = 0.99 * far;
    bool foreground = true;
    float depthGR = getDepth(texcoord.st);
	#ifdef MOONRAYS
	
	#else
    if ((worldTime < 14000 || worldTime > 22000) && sunPosition.z < 0)
	#endif
        {
                vec2 texCoord = texcoord.st;
                vec2 delta = (texCoord - lightPos) * GR_DENSITY / float(GR_SAMPLES);
                float decay = -sunPosition.z / 100.0;
                vec3 colorGR = vec3(0.0);
                for (int i = 0; i < GR_SAMPLES; i++) {
                        texCoord -= delta;
                        if (texCoord.x < 0.0 || texCoord.x > 1.0) {
                                if (texCoord.y < 0.0 || texCoord.y > 1.0) {
                                        break;
                                }
                        }
                        vec3 sample = vec3(0.0);
                        if (getDepth(texCoord) > threshold) {
                                sample = texture2D(composite, texCoord).rgb;
                        }
                        sample *= vec3(decay);
                        if (distance(texCoord, lightPos) > 0.05) sample *= 0.2;
                        colorGR += sample;
                        decay *= GR_DECAY;
                }
			
			colorGR.r = colorGR.r, 2.0;
			colorGR.g = colorGR.g, 2.0;
			colorGR.b = colorGR.b, 2.0;
                color = (color + GR_EXPOSURE * vec4(colorGR.r * 2.55, colorGR.g * 1.12, colorGR.b * 0.50, 0.01)*(TimeSunrise+TimeNoon+TimeSunset)* clamp(1.0 - rainStrength,0.1,1.0));
                color = (color + GR_EXPOSURE * vec4(colorGR.r * 2.55, colorGR.g * 1.12, colorGR.b * 0.50, 0.01)*TimeMidnight* clamp(1.0 - rainStrength,0.1,1.0));
        }
#endif 	

#ifdef BLOOM
	int j;
	int i;
	vec4 sum = vec4(0);
        float count = 0;
    for( i= -4 ;i < 4; i++) {
        for (j = -3; j < 3; j++) {
            vec2 coord = texcoord.st + vec2(j,i) * 0.004;
                if(coord.x > 0 && coord.x < 1 && coord.y > 0 && coord.y < 1){
                    sum += texture2D(composite, coord) * BLOOM_AMOUNT;
                    count += 1;
                }
            }
    }
    sum = sum / vec4(count);
		color += sum*sum*0.012;
#endif
#ifdef CROSSPROCESS
	color.r =  color.r*1.3+0.01;
    color.g = color.g*1.2;
    color.b = color.b*0.75+0.10;
#endif
	gl_FragColor = color;
}

#ifdef DOF
vec4 getBlurredColor() {
	vec4 blurredColor = vec4(0.0);
	float depth = getDepth(texcoord.xy);
	vec2 aspectCorrection = vec2(1.0, aspectRatio) * 0.005;

	vec2 ac0_4 = 0.4 * aspectCorrection;	// 0.4
#ifdef USE_HIGH_QUALITY_BLUR
	vec2 ac0_4x0_4 = 0.4 * ac0_4;			// 0.16
	vec2 ac0_4x0_7 = 0.7 * ac0_4;			// 0.28
#endif
	
	vec2 ac0_29 = 0.29 * aspectCorrection;	// 0.29
#ifdef USE_HIGH_QUALITY_BLUR
	vec2 ac0_29x0_7 = 0.7 * ac0_29;			// 0.203
	vec2 ac0_29x0_4 = 0.4 * ac0_29;			// 0.116
#endif
	
	vec2 ac0_15 = 0.15 * aspectCorrection;	// 0.15
	vec2 ac0_37 = 0.37 * aspectCorrection;	// 0.37
#ifdef USE_HIGH_QUALITY_BLUR
	vec2 ac0_15x0_9 = 0.9 * ac0_15;			// 0.135
	vec2 ac0_37x0_9 = 0.37 * ac0_37;		// 0.1369
#endif
	
	vec2 lowSpace = texcoord.st;
	vec2 highSpace = 1.0 - lowSpace;
	space = vec2(min(lowSpace.s, highSpace.s), min(lowSpace.t, highSpace.t));
		
	if (space.s >= ac0_4.s && space.t >= ac0_4.t) {

		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, ac0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_4.s, 0.0));   
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, -ac0_4.t)); 
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_4.s, 0.0)); 
		
#ifdef USE_HIGH_QUALITY_BLUR
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_4x0_7.s, 0.0));       
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, -ac0_4x0_7.t));     
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_4x0_7.s, 0.0));     
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, ac0_4x0_7.t));
	
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_4x0_4.s, 0.0));
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, -ac0_4x0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_4x0_4.s, 0.0));
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, ac0_4x0_4.t));
#endif

		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29.s, -ac0_29.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29.s, ac0_29.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29.s, ac0_29.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29.s, -ac0_29.t));
	
#ifdef USE_HIGH_QUALITY_BLUR
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29x0_7.s, ac0_29x0_7.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29x0_7.s, -ac0_29x0_7.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29x0_7.s, ac0_29x0_7.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29x0_7.s, -ac0_29x0_7.t));
		
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29x0_4.s, ac0_29x0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29x0_4.s, -ac0_29x0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29x0_4.s, ac0_29x0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29x0_4.s, -ac0_29x0_4.t));
#endif		
		
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_15.s, ac0_37.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_37.s, ac0_15.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_37.s, -ac0_15.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_15.s, -ac0_37.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_15.s, ac0_37.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_37.s, ac0_15.t)); 
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_37.s, -ac0_15.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_15.s, -ac0_37.t));

#ifdef USE_HIGH_QUALITY_BLUR
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_15x0_9.s, ac0_37x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_37x0_9.s, ac0_15x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_37x0_9.s, -ac0_15x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_15x0_9.s, -ac0_37x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_15x0_9.s, ac0_37x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_37x0_9.s, ac0_15x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_37x0_9.s, -ac0_15x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_15x0_9.s, -ac0_37x0_9.t));
#endif

#ifdef USE_HIGH_QUALITY_BLUR
	    blurredColor /= 41.0;
#else
	    blurredColor /= 16.0;
#endif
	    
	} else {
		
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, ac0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_4.s, 0.0));   
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, -ac0_4.t)); 
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_4.s, 0.0)); 
		
#ifdef USE_HIGH_QUALITY_BLUR
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_4x0_7.s, 0.0));       
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, -ac0_4x0_7.t));     
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_4x0_7.s, 0.0));     
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, ac0_4x0_7.t));
	
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_4x0_4.s, 0.0));
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, -ac0_4x0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_4x0_4.s, 0.0));
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, ac0_4x0_4.t));
#endif

		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29.s, -ac0_29.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29.s, ac0_29.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29.s, ac0_29.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29.s, -ac0_29.t));
	
#ifdef USE_HIGH_QUALITY_BLUR
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29x0_7.s, ac0_29x0_7.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29x0_7.s, -ac0_29x0_7.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29x0_7.s, ac0_29x0_7.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29x0_7.s, -ac0_29x0_7.t));
		
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29x0_4.s, ac0_29x0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29x0_4.s, -ac0_29x0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29x0_4.s, ac0_29x0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29x0_4.s, -ac0_29x0_4.t));
#endif
				
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_15.s, ac0_37.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37.s, ac0_15.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_37.s, -ac0_15.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15.s, -ac0_37.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15.s, ac0_37.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_37.s, ac0_15.t)); 
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37.s, -ac0_15.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_15.s, -ac0_37.t));
		
#ifdef USE_HIGH_QUALITY_BLUR
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_15x0_9.s, ac0_37x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37x0_9.s, ac0_15x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_37x0_9.s, -ac0_15x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15x0_9.s, -ac0_37x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15x0_9.s, ac0_37x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_37x0_9.s, ac0_15x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37x0_9.s, -ac0_15x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_15x0_9.s, -ac0_37x0_9.t));
#endif
	
	    blurredColor /= samples;
	    
	}

    return blurredColor;
}

vec4 getSampleWithBoundsCheck(vec2 offset) {
	vec2 coord = texcoord.st + offset;
	if (coord.s <= 1.0 && coord.s >= 0.0 && coord.t <= 1.0 && coord.t >= 0.0) {
		samples += 1.0;
		return texture2D(composite, coord);
	} else {
		return vec4(0.0);
	}
}
#endif