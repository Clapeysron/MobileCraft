precision mediump float;
uniform sampler2D texture_pic;
//uniform sampler2D shadowMap;

varying vec3 FragPos;
varying vec3 Normal;
varying vec2 TexCoord;
//varying vec4 FragPosLightSpace;
varying float shadow;
varying float brightness;
varying vec4 ViewPos;

struct Sunlight {
    vec3 lightDirection;
    vec3 ambient;
    vec3 lightambient;
};

uniform Sunlight sunlight;

//float ShadowCalculation(vec4 fragPosLightSpace)
//{
//    // perform perspective divide
//    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
//    // transform to [0,1] range
//    projCoords = projCoords * 0.5 + 0.5;
//    // get closest depth value from light's perspective (using [0,1] range fragPosLight as coords)
//    float closestDepth = texture2D(shadowMap, projCoords.xy).r;
//    // get depth of current fragment from light's perspective
//    float currentDepth = projCoords.z;
//    // check whether current frag pos is in shadow
//    vec3 normal = normalize(Normal);
//    vec3 lightDir = normalize(-sunlight.lightDirection);
//    float bias = max(0.0008 * (1.0 - dot(normal, lightDir)), 0.0008);
//
//    float shadow = 0.0;
//    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
//    for(int x = -1; x <= 1; ++x)
//    {
//        for(int y = -1; y <= 1; ++y)
//        {
//            float pcfDepth = texture2D(shadowMap, projCoords.xy + vec2(x, y) * texelSize).r;
//            shadow += currentDepth - bias > pcfDepth  ? 1.0 : 0.0;
//        }
//    }
//    shadow /= 9.0;
//    if(projCoords.z > 1.0)
//        shadow = 0.0;
//    //float shadow = (currentDepth - 0.0005) > closestDepth  ? 1.0 : 0.0;
//    return shadow;
//}

//float isChosen(vec3 FragPos) {
//    if ( FragPos.x < chosen_block_pos.x || FragPos.x > chosen_block_pos.x + 1.0 ||
//         FragPos.y < chosen_block_pos.y || FragPos.y > chosen_block_pos.y + 1.0 ||
//         FragPos.z < chosen_block_pos.z || FragPos.z > chosen_block_pos.z + 1.0 ) return 1.0;
//    return 1.4;
//}

void main()
{
    vec3 color = texture2D(texture_pic, TexCoord).rgb;
    float alpha = texture2D(texture_pic, TexCoord).a;
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(-sunlight.lightDirection);
    float diff = max(dot(lightDir, norm), 0.0);
    vec3 diffuse;
    if (shadow == -1.0) {
        diffuse = (sunlight.lightambient-vec3(0.095))*10.0;
    } else {
        diffuse = sunlight.lightambient * diff;
    }
    //float isChosen = isChosen(FragPos);

    //float shadow = ShadowCalculation(FragPosLightSpace);
    vec3 result;
    vec3 point_light_ambient = vec3(1.0, 0.9, 0.8);
    if (alpha >= 0.05) {
        // Without Shadow mapping
        //result = (sunlight.ambient + diffuse) * isChosen * color;
        // With Shadow mapping
        vec3 sun_bright = (1.1 - shadow) * diffuse;
        vec3 point_bright = point_light_ambient * brightness;
        float tmpShadow = shadow;
        if(tmpShadow == -1.0) tmpShadow = 1.0;
        else if(tmpShadow > 1.0) tmpShadow = 1.0;
        else tmpShadow = 0.7*tmpShadow + 0.3;
        result = tmpShadow * (sunlight.ambient + mix(sun_bright, point_bright, point_bright.r/(sunlight.lightambient.r+point_bright.r)) ) * color;
    } else {
        discard;
    }
    
    gl_FragColor = vec4(result, alpha);
}
