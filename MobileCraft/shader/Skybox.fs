precision highp float;

varying vec2 SkyTexCoords;
varying vec3 starPos;
uniform sampler2D skybox;
uniform samplerCube star;
uniform float starIntensity;
void main()
{
    gl_FragColor = (1.0-starIntensity) * texture2D(skybox, SkyTexCoords) + starIntensity * textureCube(star, starPos);
}
