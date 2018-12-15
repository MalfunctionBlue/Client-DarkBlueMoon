#version 120

varying vec4 color;
varying vec4 texcoord;

varying vec3 normal;

varying float distance;

void main() {
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;


	color = gl_Color;

	vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;

	distance = length(viewVertex);

	gl_Position = gl_ProjectionMatrix * viewVertex;
	
	//gl_FogFragCoord = 1.0;
	gl_FogFragCoord = distance*sqrt(3.0);

	normal = normalize(gl_NormalMatrix * gl_Normal);
}
