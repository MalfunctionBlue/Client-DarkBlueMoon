#version 120

varying vec4 color;


varying vec3 normal;

varying float distance;

void main() {



	color = gl_Color;

	vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;

	distance = length(viewVertex);

	gl_Position = gl_ProjectionMatrix * viewVertex;

	//gl_FogFragCoord = gl_Position.z;
	gl_FogFragCoord = distance*sqrt(3.0);

	normal = normalize(gl_NormalMatrix * gl_Normal);
}