#version 120

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

//////////////////////////////main//////////////////////////////

void main() {
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    
    color = gl_Color;

    vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;
    gl_FogFragCoord = length(viewVertex);
    
    gl_Position = gl_ProjectionMatrix * viewVertex;
    
    normal = normalize(gl_NormalMatrix * gl_Normal);
}

//////////////////////////////main//////////////////////////////
