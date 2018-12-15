#version 120

uniform int fogMode;

varying vec4 color;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

//////////////////////////////main//////////////////////////////

void main() {
    // boxes, lines
    float fogFactor = float(GL_EXP == fogMode) * (1.0f - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0f, 1.0f));
    fogFactor += float(GL_LINEAR == fogMode) * clamp(1.0f * (gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0f, 1.0f);
    
/* DRAWBUFFERS:034 */
    gl_FragData[0] = color;
    gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, fogFactor) * vec3(0.75f, 0.82f, 1.0f);
    gl_FragData[1] = gl_FragData[0];
    gl_FragData[2] = vec4(0.0f, 0.1f, 0.0f, 1.0f); // x = spec; y = basic, textured(0.0), shadow exit(0.1), lit(0.3), hand(0.4), entity(0.6), ice(0.9), water(1.0); z = torch lightmap; w = opacity
}

//////////////////////////////main//////////////////////////////
