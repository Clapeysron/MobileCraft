precision mediump float;
attribute vec3 aPos;
attribute vec3 aNormal;
attribute vec2 aTexCoord;

//uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
//uniform mat4 lightSpaceMatrix;

varying vec3 FragPos;
varying vec3 Normal;
varying vec2 TexCoord;
//varying vec4 FragPosLightSpace;

void main()
{
    Normal = aNormal;
    FragPos = aPos;
    TexCoord = aTexCoord;
    //FragPosLightSpace = lightSpaceMatrix * vec4(aPos, 1.0);
    gl_Position = projection * view * vec4(aPos, 1.0);
}
