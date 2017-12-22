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
    GLuint Block_texure;
}
@property (strong, nonatomic) EAGLContext *context;

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
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.44f, 0.77f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    steve_projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fov), aspect, 0.1f, 1000.0f);
    steve_position = [gamelink vec3:game->steve_position];
    steve_view = GLKMatrix4MakeLookAt(steve_position.x, steve_position.y, steve_position.z, steve_position.x + cameraFront.x, steve_position.y + cameraFront.y, steve_position.z + cameraFront.z, cameraUP.x, cameraUP.y, cameraUP.z);
    game->gravity_move();
    //game->visibleChunks.calcFrustumPlane(steve_view, steve_projection);
    game->visibleChunks.updataChunks(steve_position.y, steve_position.x, steve_position.z);
    [Block_Shader use];
    [Block_Shader setMat4:@"view" value:steve_view];
    [Block_Shader setMat4:@"projection" value:steve_projection];
    [Block_Shader setVec3:@"sunlight.lightDirection" x:-1.5 y:-1.0 z:0.5];
    [Block_Shader setVec3:@"sunlight.ambient" x:0.3 y:0.3 z:0.3];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, Block_texure);
//    GLKMatrix4 model = [self GLKUnitMatrix4];
//    model = GLKMatrix4Translate(model, steve_position.x, steve_position.y, steve_position.z);
//    model =
    game->visibleChunks.drawNormQuads(steve_position.y, steve_position.x, steve_position.z);
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

- (GLKMatrix4) GLKUnitMatrix4 {
    return GLKMatrix4Make(1, 0, 0, 0,
                          0, 1, 0, 0,
                          0, 0, 1, 0,
                          0, 0, 0, 1);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
