#version 120

/*
                            _____ _____ ___________ 
                           /  ___|_   _|  _  | ___ \
                           \ `--.  | | | | | | |_/ /
                            `--. \ | | | | | |  __/ 
                           /\__/ / | | \ \_/ / |    
                           \____/  \_/  \___/\_|    

						Before editing anything here make sure you've 
						read The agreement, which you accepted by downloading
						my shaderpack. The agreement can be found here:
			http://www.minecraftforum.net/topic/1953873-164-172-sildurs-shaders-pcmacintel/
						   
*/

/* DRAWBUFFERS:024 */


const float PI = 3.1415927;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec3 wpos;
varying float iswater;

uniform sampler2D texture;
uniform int worldTime;
uniform float rainStrength;
uniform float frameTimeCounter;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

void main() {	
	
vec4 watercolor = vec4(0.1,0.22,0.4,0.75); 	
vec4 tex = texture2D(texture, texcoord.xy);
if (iswater > 0.9) tex *= watercolor;


	vec3 posxz = wpos.xyz;
	posxz.x += sin(posxz.z+frameTimeCounter)*0.2;
	posxz.z += cos(posxz.x+frameTimeCounter*0.5)*0.2;

	float wave = 0.05 * sin(2 * PI * (frameTimeCounter + posxz.x  + posxz.z / 2.0))
		        + 0.05 * sin(2 * PI * (frameTimeCounter*1.2 + posxz.x / 2.0 + posxz.z ));
	
	vec3 newnormal = vec3(sin(wave*PI),1.0-cos(wave*PI),wave);
	
	vec3 indlmap =tex.rgb*color.rgb;
	gl_FragData[0] = vec4(indlmap,tex.a*color.a);

	vec4 frag2;
		frag2 = vec4((normal) * 0.5f + 0.5f, 1.0f);			
	
if (iswater > 0.9) {
	vec3 bump = newnormal;
		bump = bump;
		float bumpmult = 0.02;	
		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								tangent.y, binormal.y, normal.y,
								tangent.z, binormal.z, normal.z);
		
		frag2 = vec4(bump * tbnMatrix * 0.5 + 0.5, 1.0);
	}
	
	gl_FragData[1] = frag2;	
	
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
	
}