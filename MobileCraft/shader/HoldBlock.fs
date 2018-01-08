precision highp float;
uniform sampler2D texture_pic;
varying vec2 TexCoord;

void main()
{
    gl_FragColor = texture2D(texture_pic, TexCoord).rgba;
}

