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
    Shader *Block_Shader;
    Shader *Skybox_Shader;
    GLuint Block_texure;
    GLuint Skybox_texture;
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
    Block_Shader = [[Shader alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Block" ofType:@"vs"] fs:[[NSBundle mainBundle] pathForResource:@"Block" ofType:@"fs"]];
    [Block_Shader setInt:@"texture_pic" value:0];
    Block_texure = [self setupTexture:@"Block.png"];
    Skybox_Shader = [[Shader alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Skybox" ofType:@"vs"] fs:[[NSBundle mainBundle] pathForResource:@"Skybox" ofType:@"fs"]];
    Skybox_texture = [self setupCubeTexture];
    //[Skybox_Shader setInt:@"skybox" value:0];
    [self setupCubeBuffer];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.44f, 0.77f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    steve_projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fov), aspect, 0.1f, 1000.0f);
    steve_position = [gamelink vec3:game->steve_position];
    steve_view = GLKMatrix4MakeLookAt(steve_position.x, steve_position.y, steve_position.z, steve_position.x + cameraFront.x, steve_position.y + cameraFront.y, steve_position.z + cameraFront.z, cameraUP.x, cameraUP.y, cameraUP.z);
    game->gravity_move(1/30);
    //game->visibleChunks.calcFrustumPlane(steve_view, steve_projection);
    game->visibleChunks.updataChunks(steve_position.y, steve_position.x, steve_position.z);
    [Block_Shader use];
    [Block_Shader setMat4:@"view" value:steve_view];
    [Block_Shader setMat4:@"projection" value:steve_projection];
    [Block_Shader setVec3:@"sunlight.lightDirection" x:-1.5 y:-1.0 z:0.5];
    [Block_Shader setVec3:@"sunlight.lightambient" x:0.9 y:0.9 z:0.9];
    [Block_Shader setVec3:@"sunlight.ambient" x:0.7 y:0.7 z:0.7];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, Block_texure);
    game->visibleChunks.drawNormQuads(steve_position.y, steve_position.x, steve_position.z);
    [self drawSkybox];
}

- (void) drawSkybox {
    glDepthFunc(GL_LEQUAL);
    [Skybox_Shader use];
    GLKMatrix4 Skyview = GLKMatrix4Make(steve_view.m00, steve_view.m01, steve_view.m02, 0, steve_view.m10, steve_view.m11, steve_view.m12, 0, steve_view.m20, steve_view.m21, steve_view.m22, 0, 0, 0, 0, 1);
    [Skybox_Shader setMat4:@"view" value:Skyview];
    [Skybox_Shader setMat4:@"projection" value:steve_projection];
    glBindVertexArray(Skybox_VAO);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, Skybox_texture);
    glDrawArrays(GL_TRIANGLES, 0, 36);
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
        
        -1.0f,  1.0f, -1.0f,
        1.0f,  1.0f, -1.0f,
        1.0f,  1.0f,  1.0f,
        1.0f,  1.0f,  1.0f,
        -1.0f,  1.0f,  1.0f,
        -1.0f,  1.0f, -1.0f,
        
        -1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f,  1.0f,
        1.0f, -1.0f, -1.0f,
        1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f,  1.0f,
        1.0f, -1.0f,  1.0f
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
