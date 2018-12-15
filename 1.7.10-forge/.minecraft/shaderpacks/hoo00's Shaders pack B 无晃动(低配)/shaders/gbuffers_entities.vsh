#version 120

varying mat3 tbnMatrix;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

//////////////////////////////main//////////////////////////////

void main() {
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    
    color = gl_Color;

    vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;
    gl_FogFragCoord = length(viewVertex);
    
    gl_Position = gl_ProjectionMatrix * viewVertex;
    
    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
    float normaly = abs(gl_Normal.y);
    vec3 tangent  = normalize(gl_NormalMatrix * vec3(gl_Normal.z + normaly,  0.0f, -gl_Normal.x));
    vec3 binormal = normalize(gl_NormalMatrix * vec3(0.0f, normaly - 1.0f, normaly));
    tbnMatrix = mat3(tangent, binormal, normal);
}

//////////////////////////////main//////////////////////////////
