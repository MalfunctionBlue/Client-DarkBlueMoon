#version 120

varying vec4 texcoord;
uniform int worldTime;
uniform float rainStrength;
	
void main() {
	gl_Position = ftransform();
	 
	texcoord = gl_MultiTexCoord0;
}
