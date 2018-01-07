precision highp float;
attribute vec3 aPos;
attribute vec3 aNormal;
attribute vec2 aTexCoord;
attribute float aShadow;
attribute float aBrightness;

//uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

varying vec3 FragPos;
varying vec3 Normal;
varying vec2 TexCoord;
//vec4 FragPosLightSpace;
varying float shadow;
varying float brightness;
varying vec4 ViewPos;

void main()
{
    Normal = aNormal;
    FragPos = aPos;
    TexCoord = aTexCoord;
    //vs_out.FragPosLightSpace = lightSpaceMatrix * vec4(aPos, 1.0f);
    shadow = aShadow;
    brightness = aBrightness;
    ViewPos = view * vec4(aPos, 1.0);
    gl_Position = projection * ViewPos;
}

