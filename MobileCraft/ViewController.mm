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

char placeBlockList[]= {(char)TORCH, COBBLESTONE, MOSSY_COBBLESTONE, STONE_BRICK, QUARTZ, GOLD, TNT, ROCK, SOIL, GRASSLAND, TRUNK, GLOWSTONE, WOOD, RED_WOOD, TINT_WOOD, DARK_WOOD, BRICK, SAND, COAL_ORE, GOLD_ORE, IRON_ORE, DIAMAND_ORE, EMERALD_ORE, TOOLBOX, SMELTER, WATERMELON, PUMPKIN, WHITE_WOOL, (char)GLASS};

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
    float broken_scale;
    float deltaTime;
    Shader *Block_Shader;
    Shader *Skybox_Shader;
    Shader *HoldBlock_Shader;
    glm::vec3 lightDirection;
    glm::vec3 prev_block_pos;
    glm::vec3 chosen_block_pos;
    bool isDaylight;
    int nowPlaceBlock;
    double holdTime;
    float starIntensity;
    float x_v;
    float y_v;
    float removeCount;
    UITouch * jumpFinger;
    UITouch * moveFinger;
    UITouch * dragFinger;
    
    GLKVector3 Sun_Moon_light;
    GLKVector3 Ambient_light;
    GLuint Block_texure;
    GLuint Star_texture;
    GLuint Sky_texture;
    GLuint Skybox_VAO;
    GLuint Skybox_VBO;
    GLuint Gui_VAO;
    GLuint Gui_VBO;
    bool moveFlag;
    bool dragHold;
    bool jumpFlag;
    bool startBreak;
    bool tryPlace;
}
@property (strong, nonatomic) EAGLContext *context;

@property (strong, nonatomic) IBOutlet UIImageView *moveButton;
@property (strong, nonatomic) IBOutlet UIImageView *jumpButton;
@property (strong, nonatomic) IBOutlet UIImageView *moveRange;
@property (strong, nonatomic) IBOutlet UIImageView *leftArrow;
@property (strong, nonatomic) IBOutlet UIImageView *rightArrow;

@end

@implementation CraftViewController

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
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    self.preferredFramesPerSecond = 60;
    [self setupGL];
    gamelink = [[GameLink alloc] init];
    game = gamelink->gameCPP;
    cameraFront = GLKVector3Make(0.0, 0.0, -1.0);
    cameraUP = GLKVector3Make(0.0, 1.0, 0.0);
    dayTime = 5.5;
    nowPlaceBlock = 0;
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    if ([touch view] == _jumpButton) {
        jumpFlag = true;
        jumpFinger = touch;
    } else if ([touch view] == _moveRange || [touch view] == _moveButton) {
        moveFinger = touch;
    } else if ([touch view] == _leftArrow) {
        nowPlaceBlock--;
        nowPlaceBlock = (nowPlaceBlock<0) ? nowPlaceBlock+(int)sizeof(placeBlockList) : nowPlaceBlock;
    } else if ([touch view] == _rightArrow) {
        nowPlaceBlock++;
        nowPlaceBlock = (nowPlaceBlock>=(int)sizeof(placeBlockList)) ? nowPlaceBlock-(int)sizeof(placeBlockList) : nowPlaceBlock;
    } else {
        holdTime = [self glGetTime];
        startBreak = true;
        dragHold = true;
        dragFinger = touch;
    }
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures
{
    return UIRectEdgeAll;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    if (moveFlag && touch == moveFinger) {
        _moveButton.center = _moveRange.center;
        moveFlag = false;
        moveFinger = nil;
    } else if (dragHold && touch == dragFinger) {
        if ([self glGetTime] - holdTime < HOLD_TIME) {
            tryPlace = true;
        }
        dragHold = false;
        dragFinger = nil;
    } else if (jumpFlag && touch == jumpFinger){
        jumpFlag = false;
        jumpFinger = nil;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    if ([touch view] == _moveRange || [touch view] == _moveButton) {
        moveFlag = true;
        CGPoint location = [touch locationInView:self.view];
        CGFloat full_x = _moveRange.frame.size.width/2;
        CGFloat full_y = _moveRange.frame.size.height/2;
        if (location.x > (_moveRange.center.x + full_x)) location.x = _moveRange.center.x + full_x;
        else if (location.x < (_moveRange.center.x - full_x)) location.x = _moveRange.center.x - full_x;
        if (location.y > (_moveRange.center.y + full_y)) location.y = _moveRange.center.y + full_y;
        else if (location.y < (_moveRange.center.y - full_y)) location.y = _moveRange.center.y - full_y;
        _moveButton.translatesAutoresizingMaskIntoConstraints = true;
        _moveButton.center = location;
        CGFloat move_x = location.x - _moveRange.center.x;
        CGFloat move_y = location.y - _moveRange.center.y;
        x_v = move_x/full_x;
        y_v = move_y/full_y;
    } else {
        CGPoint location = [touch locationInView:self.view];
        CGPoint lastLoc = [touch previousLocationInView:self.view];
        CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
        
        float sensitivity = 0.3f;
        float xoffset = diff.x * sensitivity;
        float yoffset = diff.y * sensitivity;
        yaw -= xoffset;
        pitch += yoffset;
        if (pitch > 89.9f)
            pitch = 89.9f;
        if (pitch < -89.9f)
            pitch = -89.9f;
        glm::vec3 front;
        front.x = cos(GLKMathDegreesToRadians(yaw)) * cos(GLKMathDegreesToRadians(pitch));
        front.y = sin(GLKMathDegreesToRadians(pitch));
        front.z = sin(GLKMathDegreesToRadians(yaw)) * cos(GLKMathDegreesToRadians(pitch));
        cameraFront = GLKVector3Normalize([self GLKVector3Make:front]);
    }
}

- (void)steve_move {
    GLKVector3 cameraFront_XZ = cameraFront;
    glm::vec3 new_position;
    cameraFront_XZ.y = 0;
    cameraFront_XZ = GLKVector3Normalize(cameraFront_XZ);
    GLKVector3 cameraRight_XZ = GLKVector3CrossProduct(cameraFront, cameraUP);
    cameraRight_XZ.y = 0;
    cameraRight_XZ = GLKVector3Normalize(cameraRight_XZ);
    
    new_position = game->steve_position - y_v * 6 * deltaTime * glm::vec3(cameraFront_XZ.x, 0.0f, 0.0f) + x_v * 6 * deltaTime * glm::vec3(cameraRight_XZ.x, 0.0f, 0.0f);
    game->move(new_position);
    new_position = game->steve_position - y_v * 6 * deltaTime * glm::vec3(0.0, 0.0f, cameraFront_XZ.z) + x_v * 6 * deltaTime * glm::vec3(0.0, 0.0f, cameraRight_XZ.z);
    game->move(new_position);
    steve_position = [self GLKVector3Make:game->steve_position];
}

- (void)jump_move {
    if (game->steve_in_water()) {
        game->vertical_v += (game->vertical_v>0) ? (FLOAT_UP_V - game->vertical_v) : FLOAT_UP_V;
    } else if (game->vertical_v == 0 && !game->trymove(game->steve_position-glm::vec3(0, 0.02, 0))) {
        game->vertical_v = JUMP_V * 3;
    }
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
    HoldBlock_Shader = [[Shader alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"HoldBlock" ofType:@"vs"] fs:[[NSBundle mainBundle] pathForResource:@"HoldBlock" ofType:@"fs"] id_num:2];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(0.05f, 0.05f, 0.05f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [Block_Shader use];
    [Block_Shader setMat4:@"view" value:steve_view];
    [Block_Shader setMat4:@"projection" value:steve_projection];
    [Block_Shader setVec3:@"sunlight.lightDirection" value:[self GLKVector3Make:lightDirection]];
    [Block_Shader setVec3:@"sunlight.ambient" value:Ambient_light];
    [Block_Shader setVec3:@"sunlight.lightambient" value:Sun_Moon_light];
    [Block_Shader setFloat:@"DayPos" value:dayTime/24.0];
    float broken_texture_x = floor(broken_scale*10)/10;
    [Block_Shader setFloat:@"broken_texture_x" value:broken_texture_x];
    [Block_Shader setBool:@"isDaylight" value:isDaylight];
    [Block_Shader setBool:@"eye_in_water" value:(game->steve_eye_in_water())];
    [Block_Shader setFloat:@"noFogRadius" value:RADIUS*11];
    [Block_Shader setVec3:@"chosen_block_pos" value:[self GLKVector3Make:chosen_block_pos]];
    [Block_Shader setInt:@"texture_pic" value:0];
    [Block_Shader setFloat:@"starIntensity" value:starIntensity];
    [Block_Shader setInt:@"skybox" value:1];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, Block_texure);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, Sky_texture);
    game->visibleChunks.drawNormQuads(steve_position.y, steve_position.x, steve_position.z);
    game->visibleChunks.drawTransQuads(steve_position.y, steve_position.x, steve_position.z);
    [self drawSkybox];
    [self drawHoldBlock];
}

- (void) update {
    double currentFrame = [self glGetTime];
    deltaTime = currentFrame - lastFrame;
    lastFrame = currentFrame;
    dayTime += deltaTime/30;
    dayTime = (dayTime>24) ? dayTime - 24 : dayTime;
    starIntensity = [self calStarIntensity:dayTime];
    Sun_Moon_light = [self calLight:dayTime];
    Ambient_light = [self calAmbient:dayTime];
    
    game->gravity_move(deltaTime);
    glm::vec3 old_position = game->steve_position;
    
    if (moveFlag) {
        [self steve_move];
    }
    
    if (jumpFlag) {
        [self jump_move];
    }

    float move_length = glm::length(game->steve_position - old_position);
    
    //cameraFront = GLKQuaternionRotateVector3(GLKQuaternionMakeWithAngleAndVector3Axis(deltaTime/10, cameraUP), cameraFront);
    
    chosen_block_pos = game->visibleChunks.accessibleBlock(game->steve_position, glm::vec3(cameraFront.x, cameraFront.y, cameraFront.z));
    char chosen_block_type = game->visibleChunks.getBlockType(chosen_block_pos.y, chosen_block_pos.x, chosen_block_pos.z);
    broken_scale = 0;
    if(dragHold && chosen_block_pos==prev_block_pos) {
        if ([self glGetTime] - holdTime > HOLD_TIME) {
            removeCount += deltaTime;
            float broke_time = BlockInfoMap[chosen_block_type].broke_time;
            broken_scale = (chosen_block_type>>4 == -4) ? 0 : ((removeCount<0)?0:removeCount)/broke_time;
            if (removeCount < broke_time) {
            } else {
                game->visibleChunks.removeBlock(game->steve_position, glm::vec3(cameraFront.x, cameraFront.y, cameraFront.z));
                removeCount = 0;
            }
        }
    } else {
        dragHold = false;
        removeCount = 0;
    }
    prev_block_pos = chosen_block_pos;

    if(tryPlace){
        bool ret = game->visibleChunks.placeBlock(game->steve_position, glm::vec3(cameraFront.x, cameraFront.y, cameraFront.z), placeBlockList[nowPlaceBlock]);
        tryPlace = false;
    }
    
    isDaylight = (dayTime >= 5.5 && dayTime <= 18.3);
    float shadowRadius = (RADIUS*2+1)*8*1.2;
    float dayTheta = (dayTime-SUNRISE_TIME)*M_PI/12;
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

    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    steve_projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fov), aspect, 0.1f, 1000.0f);
    jitter += move_length;
    float jitter_x = 0.10*cos(jitter);
    float jitter_y = abs(0.13*sin(jitter*1.6))-0.065;
    steve_position = [gamelink vec3:game->steve_position];
    if (game->game_perspective == FIRST_PERSON) {
        if (!game->steve_in_water() && (game->game_mode == NORMAL_MODE)) {
            steve_view = GLKMatrix4MakeLookAt(steve_position.x - jitter_x, steve_position.y - jitter_y, steve_position.z, steve_position.x -jitter_x + cameraFront.x, steve_position.y - jitter_y+ cameraFront.y, steve_position.z + cameraFront.z, cameraUP.x, cameraUP.y, cameraUP.z);
        } else {
            steve_view = GLKMatrix4MakeLookAt(steve_position.x, steve_position.y, steve_position.z, steve_position.x + cameraFront.x, steve_position.y + cameraFront.y, steve_position.z + cameraFront.z, cameraUP.x, cameraUP.y, cameraUP.z);
        }
    }
    
    //game->visibleChunks.calcFrustumPlane(steve_view, steve_projection);
    game->visibleChunks.updataChunks(steve_position.y, steve_position.x, steve_position.z);
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

- (void) drawHoldBlock {
    game->visibleChunks.HoldBlock.updateBlock((char)placeBlockList[nowPlaceBlock%sizeof(placeBlockList)]);
    glCullFace(GL_BACK);
    [HoldBlock_Shader use];
    GLKMatrix4 model = [self GLKUnitMatrix4];
    model = GLKMatrix4Translate(model, 0, -0.7, 0.0);
    model = GLKMatrix4Scale(model, 0.2*abs(self.view.bounds.size.height / self.view.bounds.size.width), 0.2, 0.0);
    model = GLKMatrix4Rotate(model, M_PI, 0, 1, 0);
    model = GLKMatrix4Translate(model, -0.5, -0.5, -0.5);
    [HoldBlock_Shader setMat4:@"model" value:model];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, Block_texure);
    glBindVertexArray(game->visibleChunks.HoldBlock.getVAO());
    glDrawArrays(GL_TRIANGLES, 0, 36);
}
    
- (void) drawSkybox {
    glDepthFunc(GL_LEQUAL);
    [Skybox_Shader use];
    GLKMatrix4 Skyview = GLKMatrix4Make(steve_view.m00, steve_view.m01, steve_view.m02, 0, steve_view.m10, steve_view.m11, steve_view.m12, 0, steve_view.m20, steve_view.m21, steve_view.m22, 0, 0, 0, 0, 1);
    [Skybox_Shader setMat4:@"view" value:Skyview];
    [Skybox_Shader setMat4:@"projection" value:steve_projection];
    [Skybox_Shader setFloat:@"DayPos" value:dayTime/24.0];
    [Skybox_Shader setFloat:@"starIntensity" value:starIntensity];
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
