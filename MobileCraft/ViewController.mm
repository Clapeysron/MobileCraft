//
//  ViewController.m
//  MobileCraft
//
//  Created by Clapeysron on 19/12/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#import "ViewController.h"
#import "GameLink.h"
#import "Shader.h"
#import <vector>

@interface CraftViewController () {
    GameLink *gamelink;
    Game *game;
    GLKVector3 steve_position;
    GLKMatrix4 steve_view;
    GLKMatrix4 steve_projection;
    GLKVector3 cameraFront;
    GLKVector3 cameraUP;
    float yaw;
    float pitch;
    float fov;
    float dayTime;
    float jitter;
    float randomSunDirection;
    double lastFrame;
    float deltaTime;
    Shader *Block_Shader;
    Shader *Skybox_Shader;
    GLKVector3 Sun_Moon_light;
    GLKVector3 Ambient_light;
    GLuint Block_texure;
    GLuint Star_texture;
    GLuint Sky_texture;
    GLuint Skybox_VAO;
    GLuint Skybox_VBO;
}
@property (strong, nonatomic) EAGLContext *context;
@property (weak, nonatomic) IBOutlet UIImageView *left_arrow;

@end

@implementation CraftViewController

- (IBAction)left:(id)sender {
    //game->move_left(cameraFront.v, cameraUP.v);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *) self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self setupGL];
    gamelink = [[GameLink alloc] init];
    game = gamelink->gameCPP;
    cameraFront = GLKVector3Make(0.0, 0.0, -1.0);
    cameraUP = GLKVector3Make(0.0, 1.0, 0.0);
    dayTime = 5.5;
    deltaTime = 0;
    jitter = 0;
    srand(0);
    randomSunDirection = fmod(rand(), 2*M_PI);
    lastFrame = [self glGetTime];
    yaw = -90;
    pitch = 0;
    fov = 45;
    [self render_initial];
    game->chunk.generateMap();
}

- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
}

- (void)render_initial {
    steve_position = [gamelink vec3:game->steve_position];
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    steve_view = GLKMatrix4MakeLookAt(steve_position.x, steve_position.y, steve_position.z, steve_position.x + cameraFront.x, steve_position.y + cameraFront.y, steve_position.z + cameraFront.z, cameraUP.x, cameraUP.y, cameraUP.z);
    steve_projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fov), aspect, 0.1f, 1000.0f);
    Block_Shader = [[Shader alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Block" ofType:@"vs"] fs:[[NSBundle mainBundle] pathForResource:@"Block" ofType:@"fs"] id_num:5];
    Block_texure = [self setupTexture:@"Block.png"];
    Skybox_Shader = [[Shader alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Skybox" ofType:@"vs"] fs:[[NSBundle mainBundle] pathForResource:@"Skybox" ofType:@"fs"] id_num:1];
    [self setupCubeBuffer];
    Star_texture = [self setupCubeTexture];
    Sky_texture = [self setupTexture:@"skybox.png"];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    double currentFrame = [self glGetTime];
    deltaTime = currentFrame - lastFrame;
    lastFrame = currentFrame;
    dayTime += deltaTime/30;
    dayTime = (dayTime>24) ? dayTime - 24 : dayTime;
    float starIntensity = [self calStarIntensity:dayTime];
    Sun_Moon_light = [self calLight:dayTime];
    Ambient_light = [self calAmbient:dayTime];
    
    glm::vec3 old_position = game->steve_position;
    
    float move_length = glm::length(game->steve_position - old_position);

    cameraFront = GLKQuaternionRotateVector3(GLKQuaternionMakeWithAngleAndVector3Axis(deltaTime/10, cameraUP), cameraFront);
    
    bool isDaylight = (dayTime >= 5.5 && dayTime <= 18.3);
    float shadowRadius = (RADIUS*2+1)*8*1.2;
    float dayTheta = (dayTime-SUNRISE_TIME)*M_PI/12;
    glm::vec3 lightDirection;
    if (isDaylight) {
        lightDirection = glm::vec3(sin(randomSunDirection)*cos(dayTheta), -sin(dayTheta), cos(randomSunDirection)*cos(dayTheta));
    } else {
        lightDirection = glm::vec3(-sin(randomSunDirection)*cos(dayTheta), sin(dayTheta), -cos(randomSunDirection)*cos(dayTheta));
    }
    
    glm::vec3 lightPos = game->steve_position;
    lightPos.y = 120.0f + shadowRadius*sin(dayTheta);
    lightPos.x += -shadowRadius*sin(randomSunDirection)*cos(dayTheta);
    lightPos.z += -shadowRadius*cos(randomSunDirection)*cos(dayTheta);
    glm::vec3 moonPos = game->steve_position;
    moonPos.y = 120.0f - shadowRadius*sin(dayTheta);
    moonPos.x += shadowRadius*sin(randomSunDirection)*cos(dayTheta);
    moonPos.z += shadowRadius*cos(randomSunDirection)*cos(dayTheta);
    
    game->gravity_move(deltaTime);
    
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    steve_projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fov), aspect, 0.1f, 1000.0f);
    jitter += move_length;
    steve_position = [gamelink vec3:game->steve_position];
    if (game->game_perspective == FIRST_PERSON) {
        if (!game->steve_in_water() && (game->game_mode == NORMAL_MODE)) {
            steve_view = GLKMatrix4MakeLookAt(steve_position.x-0.10*cos(jitter), steve_position.y-abs(0.13*sin(jitter*1.6))-0.065, steve_position.z, steve_position.x-0.10*cos(jitter) + cameraFront.x, steve_position.y + cameraFront.y-abs(0.13*sin(jitter*1.6))-0.065, steve_position.z + cameraFront.z, cameraUP.x, cameraUP.y, cameraUP.z);
        } else {
            steve_view = GLKMatrix4MakeLookAt(steve_position.x, steve_position.y, steve_position.z, steve_position.x + cameraFront.x, steve_position.y + cameraFront.y, steve_position.z + cameraFront.z, cameraUP.x, cameraUP.y, cameraUP.z);
        }
    }
    
    glClearColor(0.05f, 0.05f, 0.05f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //game->visibleChunks.calcFrustumPlane(steve_view, steve_projection);
    game->visibleChunks.updataChunks(steve_position.y, steve_position.x, steve_position.z);
    [Block_Shader use];
    [Block_Shader setMat4:@"view" value:steve_view];
    [Block_Shader setMat4:@"projection" value:steve_projection];
    [Block_Shader setVec3:@"sunlight.lightDirection" value:[self GLKVector3Make:lightDirection]];
        [Block_Shader setVec3:@"sunlight.ambient" value:Ambient_light];
    [Block_Shader setVec3:@"sunlight.lightambient" value:Sun_Moon_light];
    [Block_Shader setFloat:@"DayPos" value:dayTime/24.0];
    [Block_Shader setBool:@"isDaylight" value:isDaylight];
    [Block_Shader setBool:@"eye_in_water" value:(game->steve_eye_in_water())];
    [Block_Shader setFloat:@"noFogRadius" value:RADIUS*11];
    [Block_Shader setInt:@"texture_pic" value:0];
    [Block_Shader setInt:@"skybox" value:1];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, Block_texure);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, Sky_texture);
    game->visibleChunks.drawNormQuads(steve_position.y, steve_position.x, steve_position.z);
    game->visibleChunks.drawTransQuads(steve_position.y, steve_position.x, steve_position.z);
    [self drawSkybox];
}
    
- (GLKVector3) GLKVector3Make: (glm::vec3)vec3 {
    return GLKVector3Make(vec3.x, vec3.y, vec3.z);
}
    
- (float) calStarIntensity: (float)dayTime {
    if (dayTime >=5 && dayTime <= 6) {
        return sin((6-dayTime)*M_PI/2);
    } else if (dayTime<5 || dayTime>19) {
        return 1.0f;
    } else if (dayTime >= 18 && dayTime <= 19) {
        return sin((dayTime-18)*M_PI/2);
    } else {
        return 0.0f;
    }
}
    
- (GLKVector3) calAmbient: (float)dayTime {
    float dayLight = 0.35f;
    float nightLight = 0.1f;
    if (dayTime >=5.5 && dayTime <= 6.5) {
        float dayIntensity = sin((6.5-dayTime)*M_PI/2);
        return GLKVector3Make(dayIntensity*nightLight+(1-dayIntensity)*dayLight, dayIntensity*nightLight+(1-dayIntensity)*dayLight, dayIntensity*nightLight+(1-dayIntensity)*dayLight);
    } else if (dayTime<5.5 || dayTime>19) {
        return GLKVector3Make(nightLight, nightLight, nightLight);
    } else if (dayTime >= 17 && dayTime <= 19) {
        float dayIntensity = sin((dayTime-17)*M_PI/4);
        return GLKVector3Make(dayIntensity*nightLight+(1-dayIntensity)*dayLight, dayIntensity*nightLight+(1-dayIntensity)*dayLight, dayIntensity*nightLight+(1-dayIntensity)*dayLight);
    } else {
        return GLKVector3Make(dayLight, dayLight, dayLight);
    }
}
    
- (GLKVector3) calLight: (float)dayTime {
    float dayLight = 0.6f;
    float nightLight = 0.1f;
    if (dayTime >=5.5 && dayTime <= 6.5) {
        float dayIntensity = sin((6.5-dayTime)*M_PI/2);
        return GLKVector3Make(dayIntensity*nightLight+(1-dayIntensity)*dayLight, dayIntensity*nightLight+(1-dayIntensity)*dayLight, dayIntensity*nightLight+(1-dayIntensity)*dayLight);
    } else if (dayTime<5.5 || dayTime>19) {
        return GLKVector3Make(nightLight, nightLight, nightLight);
    } else if (dayTime >= 17 && dayTime <= 19) {
        float dayIntensity = sin((dayTime-17)*M_PI/4);
        return GLKVector3Make(dayIntensity*nightLight+(1-dayIntensity)*dayLight, dayIntensity*nightLight+(1-dayIntensity)*dayLight, dayIntensity*nightLight+(1-dayIntensity)*dayLight);
    } else {
        return GLKVector3Make(dayLight, dayLight, dayLight);
    }
}

- (double) glGetTime {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    return interval;
}
    
- (void) drawSkybox {
    glDepthFunc(GL_LEQUAL);
    [Skybox_Shader use];
    GLKMatrix4 Skyview = GLKMatrix4Make(steve_view.m00, steve_view.m01, steve_view.m02, 0, steve_view.m10, steve_view.m11, steve_view.m12, 0, steve_view.m20, steve_view.m21, steve_view.m22, 0, 0, 0, 0, 1);
    [Skybox_Shader setMat4:@"view" value:Skyview];
    [Skybox_Shader setMat4:@"projection" value:steve_projection];
    [Skybox_Shader setFloat:@"DayPos" value:dayTime/24.0];
    [Skybox_Shader setFloat:@"starIntensity" value:0];
    [Skybox_Shader setInt:@"skybox" value:0];
    [Skybox_Shader setInt:@"star" value:1];
    glBindVertexArray(Skybox_VAO);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, Sky_texture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_CUBE_MAP, Star_texture);
    glDrawArrays(GL_TRIANGLES, 0, 48);
    glBindVertexArray(0);
    glDepthFunc(GL_LESS);
}

- (GLKMatrix4) GLKUnitMatrix4 {
    return GLKMatrix4Make(1, 0, 0, 0,
                          0, 1, 0, 0,
                          0, 0, 1, 0,
                          0, 0, 0, 1);
}

- (GLuint)setupTexture:(NSString *)fileName
{
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    GLuint texName;
    glGenTextures(1, &texName);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glGenerateMipmap(GL_TEXTURE_2D);
    free(spriteData);
    return texName;
}

- (void) setupCubeBuffer {
    float skyboxVertices[] = {
        // positions
        -1.0f,  1.0f, -1.0f,
        -1.0f, -1.0f, -1.0f,
        1.0f, -1.0f, -1.0f,
        1.0f, -1.0f, -1.0f,
        1.0f,  1.0f, -1.0f,
        -1.0f,  1.0f, -1.0f,
        
        -1.0f, -1.0f,  1.0f,
        -1.0f, -1.0f, -1.0f,
        -1.0f,  1.0f, -1.0f,
        -1.0f,  1.0f, -1.0f,
        -1.0f,  1.0f,  1.0f,
        -1.0f, -1.0f,  1.0f,
        
        1.0f, -1.0f, -1.0f,
        1.0f, -1.0f,  1.0f,
        1.0f,  1.0f,  1.0f,
        1.0f,  1.0f,  1.0f,
        1.0f,  1.0f, -1.0f,
        1.0f, -1.0f, -1.0f,
        
        -1.0f, -1.0f,  1.0f,
        -1.0f,  1.0f,  1.0f,
        1.0f,  1.0f,  1.0f,
        1.0f,  1.0f,  1.0f,
        1.0f, -1.0f,  1.0f,
        -1.0f, -1.0f,  1.0f,
        
        0.0f, 1.0f, 0.0f,
        -1.0f,  1.0f, -1.0f,
        1.0f,  1.0f, -1.0f,
        
        
        0.0f, 1.0f, 0.0f,
        1.0f,  1.0f, -1.0f,
        1.0f,  1.0f,  1.0f,
        
        0.0f, 1.0f, 0.0f,
        1.0f,  1.0f,  1.0f,
        -1.0f,  1.0f,  1.0f,
        
        0.0f, 1.0f, 0.0f,
        -1.0f,  1.0f,  1.0f,
        -1.0f,  1.0f, -1.0f,
        
        0.0f, -1.0f, 0.0f,
        -1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f,  1.0f,
        
        0.0f, -1.0f, 0.0f,
        -1.0f, -1.0f,  1.0f,
        1.0f, -1.0f, -1.0f,
        
        0.0f, -1.0f, 0.0f,
        1.0f, -1.0f, -1.0f,
        1.0f, -1.0f,  1.0f,
        
        0.0f, -1.0f, 0.0f,
        1.0f, -1.0f,  1.0f,
        -1.0f, -1.0f,  1.0f
    };
    glGenVertexArrays(1, &Skybox_VAO);
    glGenBuffers(1, &Skybox_VBO);
    glBindVertexArray(Skybox_VAO);
    glBindBuffer(GL_ARRAY_BUFFER, Skybox_VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(skyboxVertices), &skyboxVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
}

- (GLuint)setupCubeTexture {
    NSString *faces[6] = {
        @"right.png",
        @"left.png",
        @"top.png",
        @"bottom.png",
        @"back.png",
        @"front.png"
    };
    GLuint texName;
    glGenTextures(1, &texName);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_CUBE_MAP, texName);
    for (int i = 0; i < 6; i++) {
        CGImageRef spriteImage = [UIImage imageNamed:faces[i]].CGImage;
        if (!spriteImage) {
            NSLog(@"Failed to load image %@", faces[i]);
        } else {
            size_t width = CGImageGetWidth(spriteImage);
            size_t height = CGImageGetHeight(spriteImage);
            GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
            CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
            CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
            CGContextRelease(spriteContext);
            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
            free(spriteData);
        }
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    return texName;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
