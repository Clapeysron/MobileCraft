precision highp float;
uniform sampler2D texture_pic;
uniform sampler2D skybox;

uniform float DayPos;
uniform float starIntensity;
uniform float broken_texture_x;
uniform float noFogRadius;
uniform bool eye_in_water;
uniform bool isDaylight;
const float fogDensity = 0.05;

varying vec3 FragPos;
varying vec3 Normal;
varying vec2 TexCoord;
varying float shadow;
varying float brightness;
varying vec4 ViewPos;

struct Sunlight {
    vec3 lightDirection;
    vec3 ambient;
    vec3 lightambient;
};

uniform Sunlight sunlight;

void main()
{
    vec3 color = texture2D(texture_pic, TexCoord).rgb;
    float alpha = texture2D(texture_pic, TexCoord).a;
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(-sunlight.lightDirection);
    float diff = max(dot(lightDir, norm), 0.0);
    vec3 diffuse;
    if (shadow < 0.0) {
        //diffuse = sunlight.lightambient * diff;
        diffuse = ((sunlight.lightambient.x-0.095)*10.0 > 1.0 ? vec3(1.0) : vec3((sunlight.lightambient.x-0.095)*10.0));
    } else {
        diffuse = sunlight.lightambient * diff;
    }
    
    if (eye_in_water) {
        float real_water_texture_x = TexCoord.x - float(int(floor(TexCoord.x*10.0))/10) + 0.9;
        float real_water_texture_y = TexCoord.y - float(int(floor(TexCoord.y*10.0))/10) + 0.1;
        vec4 water_texture = texture2D(texture_pic, vec2(real_water_texture_x, real_water_texture_y));
        if (TexCoord.x<0.9 || TexCoord.y<0.1 || TexCoord.y>0.3) {
            color = 0.5 * mix(water_texture.rgb, color, 0.6);
        }
    }
    
    vec3 result;
    vec3 point_light_ambient = vec3(1.0, 0.9, 0.8);
    if (alpha >= 0.05) {
        // Without Shadow mapping
        //result = (sunlight.ambient + diffuse) * isChosen * color;
        // With Shadow mapping
        vec3 sun_bright = 1.0 * diffuse;
        vec3 point_bright = point_light_ambient * brightness;
        float tmpShadow = shadow;
        if(tmpShadow < 0.0) tmpShadow = 1.0;
        else if(tmpShadow > 1.0) tmpShadow = 1.0;
        else tmpShadow = 0.7*tmpShadow + 0.3;
        result = tmpShadow * (sunlight.ambient + mix(sun_bright, point_bright, point_bright.r/(sunlight.lightambient.r+point_bright.r)) ) * color;
    } else {
        discard;
    }
    
    //fog
    float dist = (length(ViewPos)<noFogRadius) ? 0.0 : length(ViewPos)-noFogRadius;
    float fogFactor = 1.0/exp((dist*fogDensity)*(dist*fogDensity));
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    vec2 SkyTexCoords;
    if (shadow < 0.0) {
        SkyTexCoords = vec2(DayPos, 0.42);
    } else {
        SkyTexCoords = vec2(DayPos, 0.55);
    }
    
    vec4 fogColor = (1.0-starIntensity) * texture2D(skybox, SkyTexCoords) + starIntensity * vec4(0.0, 0.0, 0.0, 1.0);
    
    gl_FragColor = mix( fogColor, vec4(result, alpha), fogFactor);
}
