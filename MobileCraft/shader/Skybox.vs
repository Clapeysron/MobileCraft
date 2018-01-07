precision highp float;
attribute vec3 aPos;
varying vec2 SkyTexCoords;
varying vec3 starPos;
uniform mat4 projection;
uniform mat4 view;
uniform float DayPos;

float getBlockPos(vec3 aPos) {
    if (aPos.y == 1.0) {
        return max(abs(aPos.x),abs(aPos.z))/4.0;
    } else if (aPos.y == -1.0) {
        return (1.0-max(abs(aPos.x),abs(aPos.z))/4.0);
    } else {
        return (1.0-aPos.y)/4.0;
    }
}

void main()
{
    starPos = aPos;
    vec2 outCoord = vec2(DayPos, getBlockPos(aPos));
    SkyTexCoords = outCoord;
    vec4 pos = projection * view * vec4(aPos, 1.0);
    gl_Position = pos.xyww;
}
