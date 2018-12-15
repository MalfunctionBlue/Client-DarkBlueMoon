#version 120

varying vec4 color;
varying vec4 texcoord;

//////////////////////////////main//////////////////////////////

void main() {
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;

    color = gl_Color;

    vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;
    gl_FogFragCoord = length(viewVertex);
    
    gl_Position = gl_ProjectionMatrix * viewVertex;    
}

//////////////////////////////main//////////////////////////////
