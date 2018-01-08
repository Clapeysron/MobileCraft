precision highp float;
attribute vec3 aPos;
attribute vec2 aNormal;

uniform mat4 model;
varying vec2 TexCoord;
void main() {
    TexCoord = aNormal;
    gl_Position = model * vec4(aPos, 1.0);
}
