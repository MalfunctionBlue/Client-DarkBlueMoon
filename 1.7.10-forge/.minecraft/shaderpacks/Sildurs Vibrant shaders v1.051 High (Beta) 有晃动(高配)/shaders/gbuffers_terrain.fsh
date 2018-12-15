#version 120
#extension GL_ARB_shader_texture_lod : enable 


const int RGBA16 = 3;
const int RGB16 = 2;
const int RGB8 = 1;
const int gnormalFormat = RGB16;
const int compositeFormat = RGBA16;
const int gaux2Format = RGBA16;
const int gcolorFormat = RGB8;

const int GL_EXP = 2048;
const int GL_LINEAR = 9729;
const float bump_distance = 64.0;			//bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float pom_distance = 32.0;			//POM render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 0.1;

	
varying vec2 lmcoord;
varying vec4 color;
varying float translucent;
varying vec3 normal;

uniform sampler2D texture;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;

//Flickering fix
/*------------------------------------------------------------------*/
varying vec4 vtexcoordam; // .st for add, .pq for mul
varying vec4 vtexcoord;
uniform sampler2D normals;

const float mincoord = 1.0/4096.0;
const float maxcoord = 1.0-mincoord;

vec2 dcdx = dFdx(vtexcoord.st*vtexcoordam.pq);
vec2 dcdy = dFdy(vtexcoord.st*vtexcoordam.pq);

vec4 readTexture(in vec2 coord){
	return texture2DGradARB(texture,fract(coord)*vtexcoordam.pq+vtexcoordam.st,dcdx,dcdy);
}

vec4 readNormal(in vec2 coord){
	return texture2DGradARB(normals,fract(coord)*vtexcoordam.pq+vtexcoordam.st,dcdx,dcdy);
}
/*------------------------------------------------------------------*/

varying float glowingBlocks;

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
vec2 adjustedTexCoord = vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;	
vec4 frag2 = vec4(normal*0.5+0.5, 1.0f);		

	vec3 lightVector;	
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	} else {
		lightVector = normalize(moonPosition);
	}
	
	float dirtest = 0.4;	
	dirtest = mix(1.0-0.8*step(dot(frag2.xyz*2.0-1.0,lightVector),-0.02),0.4,float(translucent > 0.01));
    if (glowingBlocks > 0.5) dirtest = 0.57;	
	
/* DRAWBUFFERS:0246 */

	gl_FragData[0] = texture2DGradARB(texture, adjustedTexCoord.st, dcdx, dcdy) * color;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, dirtest, lmcoord.s, 1.0);
}