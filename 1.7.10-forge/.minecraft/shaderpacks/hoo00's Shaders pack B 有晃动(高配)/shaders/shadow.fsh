#version 120

uniform sampler2D texture;

varying vec4 color;
varying vec4 texcoord;

//////////////////////////////main//////////////////////////////

void main() {
    gl_FragColor = texture2D(texture, texcoord.st) * color;
    gl_FragDepth = gl_FragCoord.z;
}

//////////////////////////////main//////////////////////////////
