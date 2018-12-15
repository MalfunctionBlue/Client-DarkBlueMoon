#version 120

varying vec4 color;

//////////////////////////////main//////////////////////////////

void main() {
    color = gl_Color;
    
    vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;
    gl_FogFragCoord = length(viewVertex);
    
    gl_Position = gl_ProjectionMatrix * viewVertex;
}

//////////////////////////////main//////////////////////////////
